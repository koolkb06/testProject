import Foundation

/// 날짜별로 묶인 점들. (설계 §3 날짜별 조회)
struct DayGroup<T> {
    let day: Date          // 그 날의 자정(startOfDay)
    let points: [T]        // 시간 오름차순
}

/// 점들을 달력 기준 "하루" 단위로 그룹핑한다. 타임존은 calendar로 주입.
struct DayGrouping {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func group<T: GeoTimed>(_ pts: [T]) -> [DayGroup<T>] {
        let buckets = Dictionary(grouping: pts) { calendar.startOfDay(for: $0.timestamp) }
        return buckets.keys.sorted().map { day in
            let sorted = buckets[day]!.sorted { $0.timestamp < $1.timestamp }
            return DayGroup(day: day, points: sorted)
        }
    }
}
