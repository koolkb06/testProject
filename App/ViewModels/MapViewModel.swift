import Foundation
import CoreLocation
import UIKit

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
    @Published private(set) var dayPhotos: [Photo] = []
    @Published private(set) var dayPlanItems: [PlanItem] = []
    @Published private(set) var stats: TripStats = .zero

    /// 재생 진행도 0...1. 로드/정지 상태에서는 1(전체 경로 표시).
    @Published private(set) var playbackProgress: Double = 1
    @Published private(set) var isPlaying = false

    @Published private(set) var regionName: String?

    /// 썸네일 탭 시 원본을 보여주기 위한 선택 사진.
    @Published var selectedPhoto: Photo?
    /// 사진 저장 실패 안내.
    @Published var captureError: String?

    private let repository: TrackRepository
    private let photoRepository: PhotoRepository
    private let planRepository: PlanRepository
    private let photoService: PhotoService
    private let calendar: Calendar
    private let geocoder = CLGeocoder()

    /// 재생 총 길이(초). 경로 길이와 무관하게 일정한 시간으로 재생.
    private let playbackDuration: TimeInterval = 8
    private var timer: Timer?

    init(
        repository: TrackRepository,
        photoRepository: PhotoRepository,
        planRepository: PlanRepository,
        photoService: PhotoService = PhotoService(),
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.photoRepository = photoRepository
        self.planRepository = planRepository
        self.photoService = photoService
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
        // 조회 가능한 날짜 = 기록된 날 ∪ 계획이 있는 날 (계획만 있는 날도 지도에서 볼 수 있게)
        let trackDays = DayGrouping(calendar: calendar).group(all).map(\.day)
        let planItems = (try? planRepository.items(for: trip)) ?? []
        let planDays = CalendarGrouping.byDay(planItems, calendar: calendar) { $0.plannedAt }.map(\.day)
        availableDays = Array(Set(trackDays + planDays)).sorted()
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
        reloadPhotos(day: day)
        reloadPlanItems(day: day)
        reverseGeocodeHead()
    }

    private func reloadPhotos(day: Date) {
        guard let trip else { dayPhotos = []; return }
        let all = (try? photoRepository.photos(for: trip)) ?? []
        dayPhotos = all.filter { calendar.isDate($0.takenAt, inSameDayAs: day) }
    }

    private func reloadPlanItems(day: Date) {
        guard let trip else { dayPlanItems = []; return }
        let all = (try? planRepository.items(for: trip)) ?? []
        dayPlanItems = all
            .filter { calendar.isDate($0.plannedAt, inSameDayAs: day) }
            .sorted { $0.plannedAt < $1.plannedAt }
    }

    /// 계획 방문 경로(좌표 있는 일정을 시간순 연결). 실제 기록 경로와 구분되는 "가야 할 길".
    var plannedRouteCoordinates: [RoutePlayback.Coord] {
        PlannedRoute.coordinates(dayPlanItems)
    }

    /// 좌표가 있는 계획 지점(지도에 번호 핀 표시용, 시간순).
    var plannedStops: [PlanItem] {
        dayPlanItems.filter { $0.latitude != nil && $0.longitude != nil }
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

    /// 전체 경로 + 계획 지점을 담는 지도 영역.
    var fullRegion: RegionBox? {
        var samples = dayPoints.map {
            LocationSample(latitude: $0.latitude, longitude: $0.longitude,
                           horizontalAccuracy: 0, timestamp: $0.timestamp)
        }
        samples += plannedStops.map {
            LocationSample(latitude: $0.latitude!, longitude: $0.longitude!,
                           horizontalAccuracy: 0, timestamp: $0.plannedAt)
        }
        return RegionCalculator.bounding(samples)
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

    // MARK: - 사진

    /// 촬영한 이미지를 현재 위치와 함께 저장한다. (설계 §4)
    /// 좌표는 촬영 시점 최신 위치(호출부가 전달); 없으면 마지막 점/시작점으로 대체.
    func capturePhoto(image: UIImage, latitude: Double?, longitude: Double?, now: Date = Date()) {
        guard let trip else {
            captureError = "먼저 여행 기록을 시작해 주세요."
            return
        }
        let lat = latitude ?? dayPoints.last?.latitude ?? startCoordinate?.latitude
        let lon = longitude ?? dayPoints.last?.longitude ?? startCoordinate?.longitude
        guard let lat, let lon else {
            captureError = "위치를 확인할 수 없어 사진을 기록하지 못했습니다."
            return
        }
        do {
            let paths = try photoService.store(image: image)
            let photo = Photo(
                filePath: paths.filePath, thumbPath: paths.thumbPath,
                latitude: lat, longitude: lon, takenAt: now
            )
            try photoRepository.add(photo, to: trip)
            reloadPhotos(day: selectedDay ?? now)
        } catch {
            captureError = "사진 저장에 실패했습니다: \(error.localizedDescription)"
        }
    }

    /// 상대 경로의 이미지를 디스크에서 로드.
    func image(atRelativePath path: String) -> UIImage? {
        UIImage(contentsOfFile: PhotoStorage.absolute(path).path)
    }

    // MARK: - 내보내기 (GPX/KML)

    /// 현재 여행 전체 경로 + 사진을 파일로 내보내 공유용 URL 반환. (설계 §5)
    func exportURL(format: ExportFormat) -> URL? {
        guard let trip else { captureError = "내보낼 여행이 없습니다."; return nil }
        let points = (try? repository.points(for: trip)) ?? []
        guard !points.isEmpty else { captureError = "내보낼 경로 점이 없습니다."; return nil }

        let segments = SegmentSplitter().split(points, timestamp: { $0.timestamp })
        let photos = (try? photoRepository.photos(for: trip)) ?? []
        let waypoints = photos.map {
            Waypoint(name: "사진", latitude: $0.latitude, longitude: $0.longitude, time: $0.takenAt)
        }
        let content = TripExporter.content(
            trackName: trip.name, segments: segments, waypoints: waypoints, format: format
        )
        do {
            return try TripExporter.write(content, baseName: trip.name, format: format)
        } catch {
            captureError = "내보내기 실패: \(error.localizedDescription)"
            return nil
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
