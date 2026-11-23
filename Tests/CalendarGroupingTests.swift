import XCTest
@testable import TravelTracker

final class CalendarGroupingTests: XCTestCase {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    func date(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return f.date(from: iso)!
    }

    func testGroupsByDayAndSortsWithin() {
        let items = [
            date("2026-12-05T09:00:00+09:00"),
            date("2026-12-04T22:00:00+09:00"),
            date("2026-12-04T08:00:00+09:00"),
        ]
        let buckets = CalendarGrouping.byDay(items, calendar: calendar) { $0 }
        XCTAssertEqual(buckets.count, 2)
        XCTAssertEqual(buckets[0].items.count, 2)      // 12-04
        XCTAssertEqual(buckets[1].items.count, 1)      // 12-05
        XCTAssertTrue(buckets[0].items[0] < buckets[0].items[1])  // 내부 오름차순
        XCTAssertTrue(buckets[0].day < buckets[1].day)            // 날짜 오름차순
    }

    func testEmpty() {
        XCTAssertTrue(CalendarGrouping.byDay([Date](), calendar: calendar) { $0 }.isEmpty)
    }
}
