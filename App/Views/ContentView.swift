import SwiftUI
import CoreLocation

/// 루트 화면. 지도(MapScreen)가 메인이며, 위치 권한이 없으면 먼저 요청 배너를 보여준다.
struct ContentView: View {
    @EnvironmentObject private var recorder: TrackRecorder

    var body: some View {
        NavigationStack {
            MapScreen()
                .overlay(alignment: .center) { permissionBannerIfNeeded }
        }
    }

    @ViewBuilder
    private var permissionBannerIfNeeded: some View {
        if recorder.authorizationStatus == .notDetermined
            || recorder.authorizationStatus == .denied {
            VStack(spacing: 12) {
                Text("여행 경로를 기록하려면\n위치 '항상 허용' 권한이 필요합니다.")
                    .multilineTextAlignment(.center)
                Button("권한 요청") { recorder.requestAuthorization() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }
}
