import SwiftUI
import MapKit

/// 계획 편집 결과.
struct PlanDraft {
    var title: String
    var plannedAt: Date
    var placeName: String?
    var memo: String
    var latitude: Double?
    var longitude: Double?
}

/// 계획 항목 추가/편집 폼. item이 nil이면 새로 추가.
struct PlanItemEditView: View {
    let item: PlanItem?
    let onSave: (PlanDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var plannedAt: Date
    @State private var placeName: String
    @State private var memo: String
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var showingPicker = false

    init(item: PlanItem?, onSave: @escaping (PlanDraft) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item?.title ?? "")
        _plannedAt = State(initialValue: item?.plannedAt ?? Date())
        _placeName = State(initialValue: item?.placeName ?? "")
        _memo = State(initialValue: item?.memo ?? "")
        _latitude = State(initialValue: item?.latitude)
        _longitude = State(initialValue: item?.longitude)
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
                    Button {
                        showingPicker = true
                    } label: {
                        HStack {
                            Label("지도에서 위치 선택", systemImage: "mappin.and.ellipse")
                            Spacer()
                            if let lat = latitude, let lon = longitude {
                                Text(String(format: "%.4f, %.4f", lat, lon))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if latitude != nil {
                        Button("위치 지우기", role: .destructive) {
                            latitude = nil; longitude = nil
                        }
                    }
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
                        onSave(PlanDraft(
                            title: title, plannedAt: plannedAt,
                            placeName: placeName.isEmpty ? nil : placeName,
                            memo: memo, latitude: latitude, longitude: longitude
                        ))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingPicker) {
                LocationPickerView(
                    initial: latitude.flatMap { lat in longitude.map { CLLocationCoordinate2D(latitude: lat, longitude: $0) } }
                ) { coord in
                    latitude = coord.latitude
                    longitude = coord.longitude
                }
            }
        }
    }
}
