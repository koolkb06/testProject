import SwiftUI

/// 투두 목록. 미완료 우선 정렬, 추가/완료체크/삭제.
struct TodoView: View {
    @EnvironmentObject private var vm: TodoViewModel
    @State private var newTitle = ""
    @State private var editingItem: TodoItem?
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.items.isEmpty {
                    ContentUnavailableView(
                        "할 일이 없습니다",
                        systemImage: "checklist",
                        description: Text("아래에 할 일을 추가하세요")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.items) { item in
                            row(item)
                        }
                    }
                }
                inputBar
            }
            .navigationTitle("투두")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "calendar.badge.plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                TodoEditView(item: nil) { title, due in vm.add(title: title, dueDate: due) }
            }
            .sheet(item: $editingItem) { item in
                TodoEditView(item: item) { title, due in vm.update(item, title: title, dueDate: due) }
            }
            .onAppear { vm.reload() }
        }
    }

    private func row(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button { vm.toggle(item) } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                if let due = item.dueDate {
                    Label(Self.dueFormatter.string(from: due), systemImage: "calendar")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { editingItem = item }
        .swipeActions {
            Button(role: .destructive) { vm.delete(item) } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var inputBar: some View {
        HStack {
            TextField("할 일 추가", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addTodo)
            Button(action: addTodo) {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .background(.bar)
    }

    private func addTodo() {
        vm.add(title: newTitle)
        newTitle = ""
    }

    static let dueFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"; return f
    }()
}
