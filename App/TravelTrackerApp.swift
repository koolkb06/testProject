import SwiftUI
import SwiftData

@main
struct TravelTrackerApp: App {
    let container: ModelContainer
    @StateObject private var recorder: TrackRecorder
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var timelineViewModel: TimelineViewModel
    @StateObject private var todoViewModel: TodoViewModel

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Trip.self, TrackPoint.self, Photo.self, Profile.self,
                PlanItem.self, TodoItem.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
        self.container = container
        Log.app.info("앱 시작, ModelContainer 준비 완료")
        SampleData.seedIfRequested(container.mainContext)

        let repository = SwiftDataTrackRepository(context: container.mainContext)
        _recorder = StateObject(
            wrappedValue: TrackRecorder(
                locationService: CLLocationService(),
                repository: repository
            )
        )
        let photoRepository = SwiftDataPhotoRepository(context: container.mainContext)
        let planRepository = SwiftDataPlanRepository(context: container.mainContext)
        _mapViewModel = StateObject(
            wrappedValue: MapViewModel(
                repository: repository,
                photoRepository: photoRepository,
                planRepository: planRepository
            )
        )
        _timelineViewModel = StateObject(
            wrappedValue: TimelineViewModel(
                tripRepository: repository,
                planRepository: planRepository
            )
        )
        _todoViewModel = StateObject(
            wrappedValue: TodoViewModel(
                repository: SwiftDataTodoRepository(context: container.mainContext)
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(recorder)
                .environmentObject(mapViewModel)
                .environmentObject(timelineViewModel)
                .environmentObject(todoViewModel)
        }
        .modelContainer(container)
    }
}
