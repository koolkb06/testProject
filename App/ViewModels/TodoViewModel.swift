import Foundation

/// 투두 화면 상태. 전역 할 일 목록을 미완료 우선으로 정렬해 관리.
@MainActor
final class TodoViewModel: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private let repository: TodoRepository

    init(repository: TodoRepository) {
        self.repository = repository
    }

    func reload() {
        let all = (try? repository.all()) ?? []
        items = TodoOrdering.sorted(all)
    }

    func add(title: String, dueDate: Date? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try repository.add(TodoItem(title: trimmed, createdAt: Date(), dueDate: dueDate))
            reload()
            Log.todo.info("투두 추가 '\(trimmed, privacy: .public)' 마감=\(dueDate != nil ? "있음" : "없음", privacy: .public)")
        } catch {
            Log.todo.error("투두 추가 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(_ item: TodoItem, title: String, dueDate: Date?) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        item.title = trimmed
        item.dueDate = dueDate
        try? repository.save()
        reload()
    }

    func toggle(_ item: TodoItem) {
        item.isDone.toggle()
        try? repository.save()
        reload()
        Log.todo.debug("투두 토글 '\(item.title, privacy: .public)' → \(item.isDone, privacy: .public)")
    }

    func delete(_ item: TodoItem) {
        Log.todo.info("투두 삭제 '\(item.title, privacy: .public)'")
        try? repository.delete(item)
        reload()
    }
}
