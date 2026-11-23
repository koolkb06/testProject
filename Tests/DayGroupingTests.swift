import XCTest
@testable import TravelTracker

final class DayGroupingTests: XCTestCase {
    // 타임존 고정으로 결정적 테스트
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    func sample(_ iso: String) -> LocationSample {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return LocationSample(latitude: 35.0, longitude: 139.0,
                              horizontalAccuracy: 5, timestamp: f.date(from: iso)!)
    }

    func testGroupsByDaySorted() {
        let pts = [
            sample("2026-12-05T09:00:00+09:00"),
            sample("2026-12-04T22:00:00+09:00"),
            sample("2026-12-04T08:00:00+09:00"),
            sample("2026-12-05T20:00:00+09:00"),
        ]
        let groups = DayGrouping(calendar: calendar).group(pts)
        XCTAssertEqual(groups.count, 2)
        // 날짜 오름차순
        XCTAssertTrue(groups[0].day < groups[1].day)
        // 4일에 2점, 5일에 2점
        XCTAssertEqual(groups[0].points.count, 2)
        XCTAssertEqual(groups[1].points.count, 2)
        // 각 그룹 내부 시간 오름차순
        XCTAssertTrue(groups[0].points[0].timestamp < groups[0].points[1].timestamp)
    }

    func testEmpty() {
        XCTAssertTrue(DayGrouping(calendar: calendar).group([LocationSample]()).isEmpty)
    }
}
