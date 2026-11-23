import XCTest
@testable import TravelTracker

final class TrackPointFilterTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func sample(lat: Double, lon: Double, acc: Double, offset: TimeInterval = 0) -> LocationSample {
        LocationSample(latitude: lat, longitude: lon, horizontalAccuracy: acc,
                       timestamp: base.addingTimeInterval(offset))
    }

    func testFirstPointAccepted() {
        let f = TrackPointFilter()
        XCTAssertTrue(f.shouldAccept(sample(lat: 37, lon: 127, acc: 10), lastAccepted: nil))
    }

    func testRejectsPoorAccuracy() {
        let f = TrackPointFilter()
        XCTAssertFalse(f.shouldAccept(sample(lat: 37, lon: 127, acc: 150), lastAccepted: nil))
    }

    func testRejectsNegativeAccuracy() {
        let f = TrackPointFilter()
        XCTAssertFalse(f.shouldAccept(sample(lat: 37, lon: 127, acc: -1), lastAccepted: nil))
    }

    func testRejectsTooCloseToLast() {
        let f = TrackPointFilter(maxAccuracy: 100, minDistance: 20)
        let last = sample(lat: 37, lon: 127, acc: 5)
        // 약 11m 이동 → 최소 20m 미만 → 버림
        let next = sample(lat: 37.0001, lon: 127, acc: 5)
        XCTAssertFalse(f.shouldAccept(next, lastAccepted: last))
    }

    func testAcceptsWhenMovedEnough() {
        let f = TrackPointFilter(maxAccuracy: 100, minDistance: 20)
        let last = sample(lat: 37, lon: 127, acc: 5)
        // 약 33m 이동 → 수용
        let next = sample(lat: 37.0003, lon: 127, acc: 5)
        XCTAssertTrue(f.shouldAccept(next, lastAccepted: last))
    }
}
