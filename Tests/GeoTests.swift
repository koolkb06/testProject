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

    func testGeodesicEndpointsAndCount() {
        let pts = Geo.geodesic(lat1: 37.46, lon1: 126.44, lat2: 35.55, lon2: 139.78, count: 32) // ICN→NRT 유사
        XCTAssertEqual(pts.count, 33)  // count+1
        XCTAssertEqual(pts.first!.latitude, 37.46, accuracy: 1e-6)
        XCTAssertEqual(pts.last!.longitude, 139.78, accuracy: 1e-6)
        // 중간점은 두 끝 사이 경도 범위 안
        XCTAssertTrue(pts[16].longitude > 126.44 && pts[16].longitude < 139.78)
    }

    func testShortDistanceSanity() {
        // 위도 0.0001도 ≈ 약 11m
        let d = Geo.distance(lat1: 37.0, lon1: 127.0, lat2: 37.0001, lon2: 127.0)
        XCTAssertEqual(d, 11.1, accuracy: 1.0)
    }
}
