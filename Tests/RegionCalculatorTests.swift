import XCTest
@testable import TravelTracker

final class RegionCalculatorTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func p(_ lat: Double, _ lon: Double) -> LocationSample {
        LocationSample(latitude: lat, longitude: lon, horizontalAccuracy: 5, timestamp: base)
    }

    func testEmptyReturnsNil() {
        XCTAssertNil(RegionCalculator.bounding([LocationSample]()))
    }

    func testCenterIsMidpoint() {
        let box = RegionCalculator.bounding([p(37.0, 127.0), p(37.2, 127.4)], padding: 1.0, minDelta: 0)
        XCTAssertEqual(box?.centerLatitude ?? 0, 37.1, accuracy: 1e-9)
        XCTAssertEqual(box?.centerLongitude ?? 0, 127.2, accuracy: 1e-9)
        XCTAssertEqual(box?.latitudeDelta ?? 0, 0.2, accuracy: 1e-9)
        XCTAssertEqual(box?.longitudeDelta ?? 0, 0.4, accuracy: 1e-9)
    }

    func testMinDeltaFloorForSinglePoint() {
        let box = RegionCalculator.bounding([p(37.0, 127.0)], minDelta: 0.005)
        XCTAssertEqual(box?.latitudeDelta ?? 0, 0.005, accuracy: 1e-9)
        XCTAssertEqual(box?.longitudeDelta ?? 0, 0.005, accuracy: 1e-9)
    }
}
