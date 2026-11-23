import Foundation

/// 투두 정렬 규칙을 순수하게 분리. 미완료 우선 → 정렬 날짜 오름차순 → 완료는 뒤로.
protocol TodoOrderable {
    var isDone: Bool { get }
    /// 정렬 기준 날짜(마감일이 있으면 마감일, 없으면 생성일).
    var orderDate: Date { get }
}

enum TodoOrdering {
    static func sorted<T: TodoOrderable>(_ items: [T]) -> [T] {
        items.sorted { a, b in
            if a.isDone != b.isDone { return !a.isDone }  // 미완료가 앞
            return a.orderDate < b.orderDate
        }
    }
}
