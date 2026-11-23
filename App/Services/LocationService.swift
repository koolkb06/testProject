import Foundation
import CoreLocation

/// 위치 공급자 추상화. 실제 GPS(`CLLocationService`) 대신 Mock을 주입해 테스트한다.
protocol LocationServing: AnyObject {
    var onSample: ((LocationSample) -> Void)? { get set }
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }

    /// "항상 허용" 권한 요청.
    func requestAuthorization()
    func start()
    func stop()
}

/// CoreLocation 기반 실제 구현. (설계 §2)
/// - "항상 허용" + Background Mode(location)
/// - 20m 이동마다 갱신(distanceFilter), 코드 필터로 추가 선별
/// - 정지 시 자동 일시정지로 배터리 절약
/// - 앱 종료 후 Significant Location Change로 재기동
final class CLLocationService: NSObject, LocationServing, CLLocationManagerDelegate {
    var onSample: ((LocationSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    private let manager: CLLocationManager

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 20
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = true
        // 앱이 백그라운드/종료 후에도 기록을 이어가기 위한 설정
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func start() {
        manager.startUpdatingLocation()
        // 앱이 종료되어도 iOS가 다시 깨우도록
        manager.startMonitoringSignificantLocationChanges()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            onSample?(Self.sample(from: location))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 1단계에서는 무시(일시적 오류는 다음 업데이트로 복구). 추후 로깅.
    }

    static func sample(from location: CLLocation) -> LocationSample {
        LocationSample(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: location.speed,
            timestamp: location.timestamp
        )
    }
}
