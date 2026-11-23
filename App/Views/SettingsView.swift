import SwiftUI

/// 프로필/설정 화면. 2단계에서는 진입 지점과 기본 정보만. (프로필 사진·편집은 추후)
struct SettingsView: View {
    @EnvironmentObject private var recorder: TrackRecorder

    var body: some View {
        List {
            Section("프로필") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text("여행자")
                }
            }
            Section("여행") {
                LabeledContent("출발 지점", value: HomeLocation.default.address)
                LabeledContent("위치 권한", value: authText)
            }
            Section {
                Text("프로필 사진, GPX/KML 내보내기는 이후 단계에서 추가됩니다.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
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
