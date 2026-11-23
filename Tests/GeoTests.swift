import XCTest
@testable import TravelTracker

final class GeoTests: XCTestCase {
    func testSamePointIsZero() {
        let d = Geo.distance(lat1: 37.0, lon1: 127.0, lat2: 37.0, lon2: 127.0)
        XCTAssertEqual(d, 0, accuracy: 0.001)
    }

    func testOneDegreeLatitudeIsAbout111km() {
        let d = Geo.distance(lat1: 37.0, lon1: 127.0, lat2: 38.0, lon2: 127.0)
        // 위도 1도 ≈ 111.19km
        XCTAssertEqual(d, 111_195, accuracy: 500)
    }

    func testShortDistanceSanity() {
        // 위도 0.0001도 ≈ 약 11m
        let d = Geo.distance(lat1: 37.0, lon1: 127.0, lat2: 37.0001, lon2: 127.0)
        XCTAssertEqual(d, 11.1, accuracy: 1.0)
    }
}
