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
                PlanItemEditView(item: nil) { title, date, place, memo in
                    vm.add(title: title, plannedAt: date, placeName: place, memo: memo)
                }
            }
            .sheet(item: $editingItem) { item in
                PlanItemEditView(item: item) { title, date, place, memo in
                    vm.update(item, title: title, plannedAt: date, placeName: place, memo: memo)
                }
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
                    if let place = item.placeName, !place.isEmpty {
                        Label(place, systemImage: "mappin.and.ellipse")
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

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"; return f
    }()
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"; return f
    }()
}
