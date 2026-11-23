import Foundation
import SwiftData

/// 투두 저장소. 전역 목록(여행에 묶이지 않음).
protocol TodoRepository {
    func add(_ item: TodoItem) throws
    func all() throws -> [TodoItem]
    func save() throws
    func delete(_ item: TodoItem) throws
}

final class SwiftDataTodoRepository: TodoRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ item: TodoItem) throws {
        context.insert(item)
        try context.save()
    }

    func all() throws -> [TodoItem] {
        try context.fetch(FetchDescriptor<TodoItem>())
    }

    func save() throws {
        try context.save()
    }

    func delete(_ item: TodoItem) throws {
        context.delete(item)
        try context.save()
    }
}
