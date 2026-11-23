import SwiftUI

/// 계획 항목 추가/편집 폼. item이 nil이면 새로 추가.
struct PlanItemEditView: View {
    let item: PlanItem?
    /// (title, plannedAt, placeName, memo)
    let onSave: (String, Date, String?, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var plannedAt: Date
    @State private var placeName: String
    @State private var memo: String

    init(item: PlanItem?, onSave: @escaping (String, Date, String?, String) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item?.title ?? "")
        _plannedAt = State(initialValue: item?.plannedAt ?? Date())
        _placeName = State(initialValue: item?.placeName ?? "")
        _memo = State(initialValue: item?.memo ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("일정") {
                    TextField("제목", text: $title)
                    DatePicker("날짜·시간", selection: $plannedAt)
                }
                Section("장소") {
                    TextField("장소명 (선택)", text: $placeName)
                }
                Section("메모") {
                    TextField("메모 (선택)", text: $memo, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle(item == nil ? "일정 추가" : "일정 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(title, plannedAt, placeName, memo)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
