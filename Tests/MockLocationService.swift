import Foundation
import CoreLocation
@testable import TravelTracker

/// 테스트용 위치 공급자. GPS 없이 샘플을 수동으로 주입한다.
final class MockLocationService: LocationServing {
    var onSample: ((LocationSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var authorizationStatus: CLAuthorizationStatus = .authorizedAlways

    private(set) var started = false
    private(set) var requestedAuthorization = false

    func requestAuthorization() {
        requestedAuthorization = true
    }

    func start() { started = true }
    func stop() { started = false }

    /// 샘플 1개를 파이프라인에 흘려보낸다.
    func emit(_ sample: LocationSample) {
        onSample?(sample)
    }

    func changeAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        onAuthorizationChange?(status)
    }
}
