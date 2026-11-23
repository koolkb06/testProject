import SwiftUI
import MapKit

/// 계획 편집 결과 (한 이동 구간).
struct PlanDraft {
    var title: String
    var plannedAt: Date
    var transport: LegTransport
    var memo: String
    var fromPlaceName: String?
    var fromLatitude: Double?
    var fromLongitude: Double?
    var toPlaceName: String?
    var toLatitude: Double?
    var toLongitude: Double?
}

/// 계획 항목(이동 구간) 추가/편집 폼. item이 nil이면 새로 추가.
struct PlanItemEditView: View {
    let item: PlanItem?
    let onSave: (PlanDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var plannedAt: Date
    @State private var transport: LegTransport
    @State private var memo: String
    @State private var fromPlaceName: String
    @State private var fromCoord: CLLocationCoordinate2D?
    @State private var toPlaceName: String
    @State private var toCoord: CLLocationCoordinate2D?
    @State private var picking: Picking?

    private enum Picking: Identifiable { case from, to; var id: Int { self == .from ? 0 : 1 } }

    init(item: PlanItem?, onSave: @escaping (PlanDraft) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item?.title ?? "")
        _plannedAt = State(initialValue: item?.plannedAt ?? Date())
        _transport = State(initialValue: item?.transport ?? .car)
        _memo = State(initialValue: item?.memo ?? "")
        _fromPlaceName = State(initialValue: item?.fromPlaceName ?? "")
        _toPlaceName = State(initialValue: item?.toPlaceName ?? "")
        _fromCoord = State(initialValue: Self.coord(item?.fromLatitude, item?.fromLongitude))
        _toCoord = State(initialValue: Self.coord(item?.toLatitude, item?.toLongitude))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("일정") {
                    TextField("제목", text: $title)
                    DatePicker("날짜·시간", selection: $plannedAt)
                    Picker("이동 수단", selection: $transport) {
                        ForEach(LegTransport.allCases) { t in
                            Label(t.label, systemImage: t.systemImage).tag(t)
                        }
                    }
                }
                Section {
                    TextField("출발 장소명 (선택)", text: $fromPlaceName)
                    locationButton(title: "출발지 지도에서 선택", coord: fromCoord) { picking = .from }
                    if fromCoord != nil {
                        Button("출발지 지우기", role: .destructive) { fromCoord = nil }
                    }
                } header: {
                    Text("출발지")
                } footer: {
                    Text("비우면 이전 일정의 도착지가 출발지가 됩니다.")
                }
                Section("도착지") {
                    TextField("도착 장소명 (선택)", text: $toPlaceName)
                    locationButton(title: "도착지 지도에서 선택", coord: toCoord) { picking = .to }
                    if toCoord != nil {
                        Button("도착지 지우기", role: .destructive) { toCoord = nil }
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
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(item: $picking) { which in
                LocationPickerView(initial: which == .from ? fromCoord : toCoord) { coord in
                    if which == .from { fromCoord = coord } else { toCoord = coord }
                }
            }
        }
    }

    private func locationButton(title: String, coord: CLLocationCoordinate2D?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: "mappin.and.ellipse")
                Spacer()
                if let c = coord {
                    Text(String(format: "%.4f, %.4f", c.latitude, c.longitude))
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func save() {
        onSave(PlanDraft(
            title: title, plannedAt: plannedAt, transport: transport, memo: memo,
            fromPlaceName: fromPlaceName.isEmpty ? nil : fromPlaceName,
            fromLatitude: fromCoord?.latitude, fromLongitude: fromCoord?.longitude,
            toPlaceName: toPlaceName.isEmpty ? nil : toPlaceName,
            toLatitude: toCoord?.latitude, toLongitude: toCoord?.longitude
        ))
        dismiss()
    }

    private static func coord(_ lat: Double?, _ lon: Double?) -> CLLocationCoordinate2D? {
        guard let lat, let lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
