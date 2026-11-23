import SwiftUI

/// 여행 계획(타임라인). 날짜별 일정 목록 + 추가/편집/삭제/완료체크.
struct TimelineView: View {
    @EnvironmentObject private var vm: TimelineViewModel
    @State private var editingItem: PlanItem?
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.buckets.isEmpty {
                    ContentUnavailableView(
                        "여행 계획이 없습니다",
                        systemImage: "calendar.badge.plus",
                        description: Text("오른쪽 위 + 로 일정을 추가하세요")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("타임라인")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                PlanItemEditView(item: nil) { draft in vm.add(draft) }
            }
            .sheet(item: $editingItem) { item in
                PlanItemEditView(item: item) { draft in vm.update(item, draft: draft) }
            }
            .onAppear { vm.reload() }
        }
    }

    private var list: some View {
        List {
            ForEach(vm.buckets, id: \.day) { bucket in
                Section(Self.dayFormatter.string(from: bucket.day)) {
                    ForEach(bucket.items) { item in
                        row(item)
                    }
                }
            }
        }
    }

    private func row(_ item: PlanItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button { vm.toggleDone(item) } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                HStack(spacing: 8) {
                    Text(Self.timeFormatter.string(from: item.plannedAt))
                    if let route = routeText(item) {
                        Label(route, systemImage: "arrow.triangle.turn.up.right.diamond")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !item.memo.isEmpty {
                    Text(item.memo).font(.caption).foregroundStyle(.secondary)
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

    /// "출발 → 도착" 표시. 출발 비면 "→ 도착"(이전 도착지에서 이어짐).
    private func routeText(_ item: PlanItem) -> String? {
        let from = item.fromPlaceName?.isEmpty == false ? item.fromPlaceName
            : (item.fromLatitude != nil ? "지정 위치" : nil)
        let to = item.toPlaceName?.isEmpty == false ? item.toPlaceName
            : (item.toLatitude != nil ? "지정 위치" : nil)
        switch (from, to) {
        case let (f?, t?): return "\(f) → \(t)"
        case (nil, let t?): return "→ \(t)"
        case (let f?, nil): return "\(f) →"
        case (nil, nil): return nil
        }
    }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"; return f
    }()
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"; return f
    }()
}
