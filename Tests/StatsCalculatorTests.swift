import XCTest
@testable import TravelTracker

final class StatsCalculatorTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func s(lat: Double, lon: Double, offset: TimeInterval) -> LocationSample {
        LocationSample(latitude: lat, longitude: lon, horizontalAccuracy: 5,
                       timestamp: base.addingTimeInterval(offset))
    }

    func testEmptyAndSingle() {
        XCTAssertEqual(StatsCalculator.stats([LocationSample]()), .zero)
        XCTAssertEqual(StatsCalculator.stats([s(lat: 37, lon: 127, offset: 0)]), .zero)
    }

    func testDistanceAndDuration() {
        let pts = [
            s(lat: 37.0, lon: 127.0, offset: 0),
            s(lat: 37.001, lon: 127.0, offset: 60),   // ~111m
            s(lat: 37.002, lon: 127.0, offset: 180),  // +~111m
        ]
        let stats = StatsCalculator.stats(pts)
        XCTAssertEqual(stats.distanceMeters, 222, accuracy: 5)
        XCTAssertEqual(stats.duration, 180, accuracy: 0.001)
    }
}
