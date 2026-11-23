import Foundation

/// 임의 타입을 날짜(자정 기준)로 묶는 범용 그룹핑. 타임존은 calendar로 주입.
/// (GeoTimed 전용인 DayGrouping과 달리 날짜 추출 클로저를 받아 PlanItem 등에도 쓴다.)
struct DayBucket<T> {
    let day: Date
    let items: [T]
}

enum CalendarGrouping {
    static func byDay<T>(
        _ items: [T],
        calendar: Calendar = .current,
        date: (T) -> Date
    ) -> [DayBucket<T>] {
        let buckets = Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
        return buckets.keys.sorted().map { day in
            let sorted = buckets[day]!.sorted { date($0) < date($1) }
            return DayBucket(day: day, items: sorted)
        }
    }
}
