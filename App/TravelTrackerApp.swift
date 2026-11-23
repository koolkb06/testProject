import SwiftUI
import SwiftData

@main
struct TravelTrackerApp: App {
    let container: ModelContainer
    @StateObject private var recorder: TrackRecorder
    @StateObject private var mapViewModel: MapViewModel

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Trip.self, TrackPoint.self, Photo.self, Profile.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
        self.container = container

        let repository = SwiftDataTrackRepository(context: container.mainContext)
        _recorder = StateObject(
            wrappedValue: TrackRecorder(
                locationService: CLLocationService(),
                repository: repository
            )
        )
        _mapViewModel = StateObject(
            wrappedValue: MapViewModel(repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recorder)
                .environmentObject(mapViewModel)
        }
        .modelContainer(container)
    }
}
