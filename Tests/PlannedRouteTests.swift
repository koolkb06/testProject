import XCTest
@testable import TravelTracker

private struct FakeLeg: PlannedLegSource {
    var fromLatitude: Double?
    var fromLongitude: Double?
    var toLatitude: Double?
    var toLongitude: Double?
    var plannedAt: Date
    var title: String
    var isDone: Bool = false
}

final class PlannedRouteTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func testExplicitFromMakesLeg() {
        let items = [
            FakeLeg(fromLatitude: 37.0, fromLongitude: 127.0,
                    toLatitude: 37.1, toLongitude: 127.1,
                    plannedAt: base, title: "A"),
        ]
        let r = PlannedRoute.build(items)
        XCTAssertEqual(r.stops.count, 1)
        XCTAssertEqual(r.legs.count, 1)
        XCTAssertEqual(r.legs[0].from, .init(latitude: 37.0, longitude: 127.0))
        XCTAssertEqual(r.legs[0].to, .init(latitude: 37.1, longitude: 127.1))
    }

    func testMissingFromChainsFromPreviousArrival() {
        let items = [
            FakeLeg(fromLatitude: 37.0, fromLongitude: 127.0,
                    toLatitude: 37.1, toLongitude: 127.1, plannedAt: base, title: "A"),
            // 출발 없음 → 이전 도착(37.1,127.1)에서 이어짐
            FakeLeg(fromLatitude: nil, fromLongitude: nil,
                    toLatitude: 37.2, toLongitude: 127.2,
                    plannedAt: base.addingTimeInterval(100), title: "B"),
        ]
        let r = PlannedRoute.build(items)
        XCTAssertEqual(r.legs.count, 2)
        XCTAssertEqual(r.legs[1].from, .init(latitude: 37.1, longitude: 127.1))
        XCTAssertEqual(r.legs[1].to, .init(latitude: 37.2, longitude: 127.2))
        XCTAssertEqual(r.stops.map(\.order), [1, 2])
    }

    func testFirstWithoutFromHasStopButNoLeg() {
        let items = [
            FakeLeg(fromLatitude: nil, fromLongitude: nil,
                    toLatitude: 37.5, toLongitude: 127.5, plannedAt: base, title: "첫 도착"),
        ]
        let r = PlannedRoute.build(items)
        XCTAssertEqual(r.stops.count, 1)
        XCTAssertEqual(r.legs.count, 0)  // 출발 없음 + 이전 없음 → 선 없음
    }

    func testSortsByTimeAndSkipsItemsWithoutArrival() {
        let items = [
            FakeLeg(fromLatitude: nil, fromLongitude: nil,
                    toLatitude: 37.3, toLongitude: 127.3,
                    plannedAt: base.addingTimeInterval(300), title: "늦음"),
            FakeLeg(fromLatitude: nil, fromLongitude: nil,
                    toLatitude: nil, toLongitude: nil,
                    plannedAt: base.addingTimeInterval(100), title: "도착없음"),
            FakeLeg(fromLatitude: 37.0, fromLongitude: 127.0,
                    toLatitude: 37.1, toLongitude: 127.1,
                    plannedAt: base.addingTimeInterval(200), title: "이름"),
        ]
        let r = PlannedRoute.build(items)
        // 도착 있는 2개만 정류장, 시간순(200 → 300)
        XCTAssertEqual(r.stops.map(\.title), ["이름", "늦음"])
    }
}
