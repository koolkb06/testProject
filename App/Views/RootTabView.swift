import SwiftUI

/// 앱 루트 탭: 지도 / 타임라인 / 투두. (설정은 지도 좌상단 버튼으로 진입)
struct RootTabView: View {
    @State private var selection: Tab

    enum Tab: String { case map, timeline, todo }

    init() {
        // 헤드리스 캡처/테스트용: 환경변수 START_TAB로 초기 탭 지정 가능.
        let initial = ProcessInfo.processInfo.environment["START_TAB"].flatMap(Tab.init) ?? .map
        _selection = State(initialValue: initial)
    }

    var body: some View {
        TabView(selection: $selection) {
            ContentView()
                .tabItem { Label("지도", systemImage: "map.fill") }
                .tag(Tab.map)

            TimelineView()
                .tabItem { Label("타임라인", systemImage: "calendar") }
                .tag(Tab.timeline)

            TodoView()
                .tabItem { Label("투두", systemImage: "checklist") }
                .tag(Tab.todo)
        }
    }
}
