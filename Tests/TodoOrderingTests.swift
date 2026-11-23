import XCTest
@testable import TravelTracker

private struct FakeTodo: TodoOrderable {
    var isDone: Bool
    var orderDate: Date
    var label: String
}

final class TodoOrderingTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func testIncompleteBeforeComplete() {
        let items = [
            FakeTodo(isDone: true, orderDate: base, label: "done"),
            FakeTodo(isDone: false, orderDate: base.addingTimeInterval(100), label: "todo"),
        ]
        let sorted = TodoOrdering.sorted(items)
        XCTAssertEqual(sorted.map(\.label), ["todo", "done"])
    }

    func testWithinSameStatusSortedByDate() {
        let items = [
            FakeTodo(isDone: false, orderDate: base.addingTimeInterval(200), label: "b"),
            FakeTodo(isDone: false, orderDate: base.addingTimeInterval(100), label: "a"),
            FakeTodo(isDone: false, orderDate: base.addingTimeInterval(300), label: "c"),
        ]
        XCTAssertEqual(TodoOrdering.sorted(items).map(\.label), ["a", "b", "c"])
    }

    func testTodoItemOrderDateUsesDueThenCreated() {
        let created = base
        let due = base.addingTimeInterval(500)
        let withDue = TodoItem(title: "x", createdAt: created, dueDate: due)
        XCTAssertEqual(withDue.orderDate, due)
        let noDue = TodoItem(title: "y", createdAt: created, dueDate: nil)
        XCTAssertEqual(noDue.orderDate, created)
    }
}
