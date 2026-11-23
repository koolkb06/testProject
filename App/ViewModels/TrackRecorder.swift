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
    private let home: HomeLocation

    private var trip: Trip?
    private var lastAccepted: LocationSample?

    init(
        locationService: LocationServing,
        repository: TrackRepository,
        filter: TrackPointFilter = TrackPointFilter(),
        home: HomeLocation = .default
    ) {
        self.locationService = locationService
        self.repository = repository
        self.filter = filter
        self.home = home
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
        guard !isRecording else { return }
        do {
            if let active = try repository.activeTrip() {
                trip = active
            } else {
                trip = try repository.startTrip(name: tripName, startDate: now, home: home)
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
        } catch {
            // 1단계에서는 콘솔 로깅만. 추후 사용자 피드백.
            print("TrackRecorder.start 실패: \(error)")
        }
    }

    func stop(now: Date = Date()) {
        guard isRecording else { return }
        locationService.stop()
        isRecording = false
        if let trip {
            try? repository.endTrip(trip, endDate: now)
        }
    }

    private func handle(_ sample: LocationSample) {
        lastSample = sample
        guard isRecording, let trip else { return }
        guard filter.shouldAccept(sample, lastAccepted: lastAccepted) else { return }
        do {
            try repository.append(sample, to: trip)
            lastAccepted = sample
            pointCount += 1
        } catch {
            print("TrackRecorder.append 실패: \(error)")
        }
    }
}
