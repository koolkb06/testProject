import Foundation
import CoreLocation

/// 지도 화면 상태: 최신 여행 로드 → 날짜별 조회 → 경로 재생. (설계 §3)
/// MapKit에 의존하지 않도록 좌표는 값으로 노출하고, 뷰에서 MapKit 타입으로 변환한다.
@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var trip: Trip?
    @Published private(set) var availableDays: [Date] = []
    @Published var selectedDay: Date? {
        didSet { if !isReloading && oldValue != selectedDay { updateDay() } }
    }
    private var isReloading = false
    @Published private(set) var dayPoints: [TrackPoint] = []
    @Published private(set) var stats: TripStats = .zero

    /// 재생 진행도 0...1. 로드/정지 상태에서는 1(전체 경로 표시).
    @Published private(set) var playbackProgress: Double = 1
    @Published private(set) var isPlaying = false

    @Published private(set) var regionName: String?

    private let repository: TrackRepository
    private let calendar: Calendar
    private let geocoder = CLGeocoder()

    /// 재생 총 길이(초). 경로 길이와 무관하게 일정한 시간으로 재생.
    private let playbackDuration: TimeInterval = 8
    private var timer: Timer?

    init(repository: TrackRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    // MARK: - 로드

    func reload() {
        guard let trip = try? repository.latestTrip() else {
            self.trip = nil
            availableDays = []
            dayPoints = []
            stats = .zero
            return
        }
        self.trip = trip
        let all = (try? repository.points(for: trip)) ?? []
        availableDays = DayGrouping(calendar: calendar).group(all).map(\.day)
        if selectedDay == nil || !(availableDays.contains(selectedDay!)) {
            isReloading = true          // selectedDay didSet의 중복 updateDay 방지
            selectedDay = availableDays.last
            isReloading = false
        }
        updateDay()
    }

    private func updateDay() {
        stopPlayback()
        guard let trip, let day = selectedDay else {
            dayPoints = []
            stats = .zero
            return
        }
        let all = (try? repository.points(for: trip)) ?? []
        dayPoints = DayGrouping(calendar: calendar).group(all)
            .first { calendar.isDate($0.day, inSameDayAs: day) }?.points ?? []
        stats = StatsCalculator.stats(dayPoints)
        playbackProgress = 1
        reverseGeocodeHead()
    }

    // MARK: - 좌표 (뷰에서 CLLocationCoordinate2D로 변환)

    /// 출발 지점(집). 좌표를 알면 trip의 시작점, 아니면 그날 첫 점. (설계: 흰색 네모 마커)
    var startCoordinate: RoutePlayback.Coord? {
        if let lat = trip?.startLatitude, let lon = trip?.startLongitude {
            return .init(latitude: lat, longitude: lon)
        }
        return dayPoints.first.map { .init(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// 현재 진행도까지 그려진 경로.
    var drawnCoordinates: [RoutePlayback.Coord] {
        RoutePlayback.drawnCoordinates(dayPoints, progress: playbackProgress)
    }

    /// 재생 머리(= 프로필 마커) 위치.
    var headCoordinate: RoutePlayback.Coord? {
        RoutePlayback.position(dayPoints, progress: playbackProgress)
    }

    /// 전체 경로를 담는 지도 영역.
    var fullRegion: RegionBox? {
        RegionCalculator.bounding(dayPoints)
    }

    // MARK: - 재생

    func togglePlayback() {
        isPlaying ? pausePlayback() : play()
    }

    func play() {
        guard dayPoints.count > 1 else { return }
        if playbackProgress >= 1 { playbackProgress = 0 }
        isPlaying = true
        let step = (1.0 / 60.0) / playbackDuration
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick(step: step) }
        }
    }

    func pausePlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    /// 재생 중단 + 전체 경로 표시로 복귀.
    private func stopPlayback() {
        pausePlayback()
        playbackProgress = 1
    }

    private func tick(step: Double) {
        playbackProgress = min(playbackProgress + step, 1)
        if playbackProgress >= 1 {
            pausePlayback()
            reverseGeocodeHead()
        }
    }

    // MARK: - 현재 지역명 (best-effort)

    private func reverseGeocodeHead() {
        guard let head = headCoordinate else { regionName = nil; return }
        let location = CLLocation(latitude: head.latitude, longitude: head.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                let p = placemarks?.first
                self?.regionName = p?.locality ?? p?.administrativeArea ?? p?.country
            }
        }
    }
}
