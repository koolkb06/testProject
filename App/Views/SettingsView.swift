import SwiftUI
import MapKit

/// 프로필/설정 화면. 집 위치 교정, 권한 상태 등.
struct SettingsView: View {
    @EnvironmentObject private var recorder: TrackRecorder
    @State private var home: HomeLocation = .current
    @State private var showingPicker = false
    @State private var googleKey: String = GoogleConfig.apiKey ?? ""

    var body: some View {
        List {
            Section("프로필") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text("여행자")
                }
            }
            Section("집 (출발 지점)") {
                LabeledContent("주소", value: home.address)
                if let lat = home.latitude, let lon = home.longitude {
                    LabeledContent("좌표", value: String(format: "%.5f, %.5f", lat, lon))
                }
                Button {
                    showingPicker = true
                } label: {
                    Label("지도에서 집 위치 지정", systemImage: "house.and.flag")
                }
                if HomeStore.load() != nil {
                    Button("기본 위치로 되돌리기", role: .destructive) {
                        HomeStore.clear()
                        home = .current
                    }
                }
            }
            Section {
                SecureField("Google Directions API 키 (선택)", text: $googleKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: googleKey) { _, v in GoogleConfig.setAPIKey(v) }
            } header: {
                Text("전철 실제 노선 (선택)")
            } footer: {
                Text("키를 넣으면 전철 구간이 실제 노선으로 그려집니다. 없으면 직선으로 표시됩니다. (자동차·도보는 Apple 지도로 키 없이 동작)")
            }
            Section("권한") {
                LabeledContent("위치 권한", value: authText)
            }
            Section {
                Text("집 위치를 지도에서 지정하면 다음 여행부터 그 지점이 출발 지점(흰 네모 마커)이 됩니다.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPicker) {
            LocationPickerView(
                initial: home.latitude.flatMap { lat in home.longitude.map { CLLocationCoordinate2D(latitude: lat, longitude: $0) } }
            ) { coord in
                let updated = HomeLocation(address: home.address, latitude: coord.latitude, longitude: coord.longitude)
                HomeStore.save(updated)
                home = updated
            }
        }
    }

    private var authText: String {
        switch recorder.authorizationStatus {
        case .authorizedAlways: return "항상 허용"
        case .authorizedWhenInUse: return "사용 중 허용"
        case .denied: return "거부됨"
        case .restricted: return "제한됨"
        case .notDetermined: return "미결정"
        @unknown default: return "알 수 없음"
        }
    }
}
