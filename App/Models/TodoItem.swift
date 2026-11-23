import Foundation
import SwiftData

/// 할 일(투두) 항목. 특정 날짜에 묶이지 않는 전역 체크리스트(여행 준비 등). (사용자 요청)
@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.dueDate = dueDate
    }
}
