import XCTest
import CoreLocation
@testable import TravelTracker

final class MyLocationTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - 권한 상태별 동작

    func testAuthorizedFollows() {
        XCTAssertEqual(MyLocation.action(for: .authorizedAlways), .follow)
        XCTAssertEqual(MyLocation.action(for: .authorizedWhenInUse), .follow)
    }

    func testNotDeterminedRequestsPermission() {
        XCTAssertEqual(MyLocation.action(for: .notDetermined), .requestPermission)
    }

    func testDeniedOrRestrictedOpensSettings() {
        XCTAssertEqual(MyLocation.action(for: .denied), .openSettings)
        XCTAssertEqual(MyLocation.action(for: .restricted), .openSettings)
    }

    // MARK: - GPS 수신 전 대체 영역

    func testFallbackPrefersLastSample() {
        let sample = LocationSample(latitude: 35.6580, longitude: 139.7016, horizontalAccuracy: 5, timestamp: base)
        let box = MyLocation.fallbackRegion(lastSample: sample, home: .default)

        XCTAssertEqual(box?.centerLatitude, 35.6580)
        XCTAssertEqual(box?.centerLongitude, 139.7016)
        XCTAssertEqual(box?.latitudeDelta, MyLocation.zoomDelta)
        XCTAssertEqual(box?.longitudeDelta, MyLocation.zoomDelta)
    }

    func testFallbackUsesHomeWhenNoSample() {
        let home = HomeLocation(address: "집", latitude: 37.332388, longitude: 127.112209)
        let box = MyLocation.fallbackRegion(lastSample: nil, home: home)

        XCTAssertEqual(box?.centerLatitude, 37.332388)
        XCTAssertEqual(box?.centerLongitude, 127.112209)
    }

    func testFallbackNilWhenNothingKnown() {
        let home = HomeLocation(address: "집", latitude: nil, longitude: nil)
        XCTAssertNil(MyLocation.fallbackRegion(lastSample: nil, home: home))
    }
}
