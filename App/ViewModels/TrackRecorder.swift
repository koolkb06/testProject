import Foundation
import CoreLocation

/// 위치 기록 오케스트레이터: Service에서 샘플을 받아 Filter로 선별 후 Repository에 저장.
/// GPS/저장을 프로토콜로 주입받아 테스트 가능.
@MainActor
final class TrackRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var pointCount = 0
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var lastSample: LocationSample?

    private let locationService: LocationServing
    private let repository: TrackRepository
    private let filter: TrackPointFilter
    /// 테스트용 고정 집 위치. nil이면 설정에서 교정 가능한 현재 집 위치(.current)를 매번 읽는다.
    private let homeOverride: HomeLocation?
    private var home: HomeLocation { homeOverride ?? .current }

    private var trip: Trip?
    private var lastAccepted: LocationSample?

    init(
        locationService: LocationServing,
        repository: TrackRepository,
        filter: TrackPointFilter = TrackPointFilter(),
        home: HomeLocation? = nil
    ) {
        self.locationService = locationService
        self.repository = repository
        self.filter = filter
        self.homeOverride = home
        self.authorizationStatus = locationService.authorizationStatus

        // CLLocationManagerDelegate 콜백은 서비스를 시작한 스레드(여기선 메인)에서 호출된다.
        // 따라서 메인 액터로 간주하고 동기 처리한다(테스트 결정성 확보).
        locationService.onAuthorizationChange = { [weak self] status in
            MainActor.assumeIsolated { self?.authorizationStatus = status }
        }
        locationService.onSample = { [weak self] sample in
            MainActor.assumeIsolated { self?.handle(sample) }
        }
    }

    func requestAuthorization() {
        locationService.requestAuthorization()
    }

    /// 기록 시작. 진행 중 여행이 있으면 이어가고, 없으면 집에서 시작하는 새 여행을 만든다.
    func start(tripName: String = "일본 여행", now: Date = Date()) {
        guard !isRecording else {
            Log.recording.notice("기록 시작 요청 무시: 이미 기록 중")
            return
        }
        do {
            if let active = try repository.activeTrip() {
                trip = active
                Log.recording.info("진행 중 여행 이어감: '\(active.name, privacy: .public)'")
            } else {
                let h = home
                trip = try repository.startTrip(name: tripName, startDate: now, home: h)
                Log.recording.info("""
                    새 여행 시작: '\(tripName, privacy: .public)' \
                    집=\(h.address, privacy: .public) \
                    좌표=\(h.latitude ?? .nan, privacy: .public),\(h.longitude ?? .nan, privacy: .public)
                    """)
            }
            if let trip {
                let existing = try repository.points(for: trip)
                pointCount = existing.count
                lastAccepted = existing.last.map {
                    LocationSample(
                        latitude: $0.latitude,
                        longitude: $0.longitude,
                        altitude: $0.altitude,
                        horizontalAccuracy: $0.horizontalAccuracy,
                        speed: $0.speed,
                        timestamp: $0.timestamp
                    )
                }
            }
            locationService.start()
            isRecording = true
            Log.recording.info("기록 시작 완료. 기존 점 수=\(self.pointCount, privacy: .public)")
        } catch {
            Log.recording.error("기록 시작 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop(now: Date = Date()) {
        guard isRecording else { return }
        locationService.stop()
        isRecording = false
        if let trip {
            do {
                try repository.endTrip(trip, endDate: now)
                Log.recording.info("기록 정지. 최종 점 수=\(self.pointCount, privacy: .public)")
            } catch {
                Log.recording.error("여행 종료 저장 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func handle(_ sample: LocationSample) {
        lastSample = sample
        guard isRecording, let trip else {
            Log.recording.debug("샘플 무시(기록중 아님)")
            return
        }
        let distance = lastAccepted.map { Geo.distance($0, sample) }
        guard filter.shouldAccept(sample, lastAccepted: lastAccepted) else {
            Log.recording.debug("""
                점 버림 acc=\(sample.horizontalAccuracy, format: .fixed(precision: 1), privacy: .public)m \
                이동=\(distance ?? -1, format: .fixed(precision: 1), privacy: .public)m \
                (정확도>\(self.filter.maxAccuracy, privacy: .public) 또는 이동<\(self.filter.minDistance, privacy: .public))
                """)
            return
        }
        do {
            try repository.append(sample, to: trip)
            lastAccepted = sample
            pointCount += 1
            Log.recording.info("""
                점 저장 #\(self.pointCount, privacy: .public) \
                lat=\(sample.latitude, privacy: .public) lon=\(sample.longitude, privacy: .public) \
                acc=\(sample.horizontalAccuracy, format: .fixed(precision: 1), privacy: .public)m \
                이동=\(distance ?? 0, format: .fixed(precision: 1), privacy: .public)m
                """)
        } catch {
            Log.recording.error("점 저장 실패: \(error.localizedDescription, privacy: .public)")
        }
    }
}
