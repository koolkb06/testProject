import SwiftUI

/// 투두 추가/편집 폼 (제목 + 선택적 마감일). item이 nil이면 새로 추가.
struct TodoEditView: View {
    let item: TodoItem?
    /// (title, dueDate?)
    let onSave: (String, Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var hasDue: Bool
    @State private var dueDate: Date

    init(item: TodoItem?, onSave: @escaping (String, Date?) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item?.title ?? "")
        _hasDue = State(initialValue: item?.dueDate != nil)
        _dueDate = State(initialValue: item?.dueDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("할 일") {
                    TextField("제목", text: $title)
                }
                Section("마감일") {
                    Toggle("마감일 설정", isOn: $hasDue.animation())
                    if hasDue {
                        DatePicker("마감", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(item == nil ? "할 일 추가" : "할 일 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(title, hasDue ? dueDate : nil)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
