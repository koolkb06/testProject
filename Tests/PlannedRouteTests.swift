import XCTest
@testable import TravelTracker

private struct FakeStop: PlannedStop {
    var latitude: Double?
    var longitude: Double?
    var plannedAt: Date
}

final class PlannedRouteTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func testOrdersByTimeAndKeepsOnlyCoordinated() {
        let stops = [
            FakeStop(latitude: 37.3, longitude: 127.3, plannedAt: base.addingTimeInterval(300)),
            FakeStop(latitude: nil, longitude: nil, plannedAt: base.addingTimeInterval(100)),  // 좌표 없음 → 제외
            FakeStop(latitude: 37.1, longitude: 127.1, plannedAt: base.addingTimeInterval(100)),
            FakeStop(latitude: 37.2, longitude: 127.2, plannedAt: base.addingTimeInterval(200)),
        ]
        let coords = PlannedRoute.coordinates(stops)
        XCTAssertEqual(coords.count, 3)
        // 시간순: 37.1 → 37.2 → 37.3
        XCTAssertEqual(coords.map { $0.latitude }, [37.1, 37.2, 37.3])
    }

    func testEmptyWhenNoCoordinates() {
        let stops = [FakeStop(latitude: nil, longitude: nil, plannedAt: base)]
        XCTAssertTrue(PlannedRoute.coordinates(stops).isEmpty)
    }
}
