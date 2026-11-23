import SwiftUI

/// 투두 목록. 미완료 우선 정렬, 추가/완료체크/삭제.
struct TodoView: View {
    @EnvironmentObject private var vm: TodoViewModel
    @State private var newTitle = ""
    @State private var editingItem: TodoItem?
    @State private var showingNew = false
    @FocusState private var inputFocused: Bool

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
                    .scrollDismissesKeyboard(.immediately)
                }
                inputBar
            }
            .navigationTitle("투두")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "calendar.badge.plus") }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { inputFocused = false }
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
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.secondary)
                TextField("할 일 추가", text: $newTitle)
                    .textFieldStyle(.plain)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit(addTodo)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
            .background(Capsule().fill(Color(.secondarySystemBackground)))

            Button(action: addTodo) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canAdd ? Color.accentColor : Color.secondary)
            }
            .disabled(!canAdd)
            .animation(.easeInOut(duration: 0.15), value: canAdd)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var canAdd: Bool {
        !newTitle.trimmingCharacters(in: .whitespaces).isEmpty
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
