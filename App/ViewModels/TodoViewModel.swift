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
        } catch {
            print("TodoViewModel.add 실패: \(error)")
        }
    }

    func toggle(_ item: TodoItem) {
        item.isDone.toggle()
        try? repository.save()
        reload()
    }

    func delete(_ item: TodoItem) {
        try? repository.delete(item)
        reload()
    }
}
