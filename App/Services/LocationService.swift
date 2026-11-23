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
        Log.location.info("CLLocationService 초기화: desiredAccuracy=best distanceFilter=20 background=on")
    }

    func requestAuthorization() {
        Log.location.info("위치 '항상 허용' 권한 요청")
        manager.requestAlwaysAuthorization()
    }

    func start() {
        Log.location.info("위치 업데이트 시작 (standard + significant change)")
        manager.startUpdatingLocation()
        // 앱이 종료되어도 iOS가 다시 깨우도록
        manager.startMonitoringSignificantLocationChanges()
    }

    func stop() {
        Log.location.info("위치 업데이트 정지")
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let s = Self.sample(from: location)
            Log.location.debug("""
                수신 lat=\(s.latitude, privacy: .public) lon=\(s.longitude, privacy: .public) \
                acc=\(s.horizontalAccuracy, format: .fixed(precision: 1), privacy: .public)m \
                speed=\(s.speed, format: .fixed(precision: 1), privacy: .public) \
                alt=\(s.altitude, format: .fixed(precision: 0), privacy: .public) \
                ts=\(s.timestamp.timeIntervalSince1970, format: .fixed(precision: 0), privacy: .public)
                """)
            onSample?(s)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Log.location.info("권한 변경: \(String(describing: manager.authorizationStatus.rawValue), privacy: .public) (accuracy=\(manager.accuracyAuthorization.rawValue, privacy: .public))")
        onAuthorizationChange?(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.location.error("위치 오류: \(error.localizedDescription, privacy: .public)")
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        Log.location.notice("위치 업데이트 일시정지(정지 상태 감지, 배터리 절약)")
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        Log.location.notice("위치 업데이트 재개")
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
