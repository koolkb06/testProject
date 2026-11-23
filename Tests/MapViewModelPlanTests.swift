import XCTest
import SwiftData
@testable import TravelTracker

@MainActor
final class MapViewModelPlanTests: XCTestCase {
    var container: ModelContainer!
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Trip.self, TrackPoint.self, Photo.self, Profile.self,
            PlanItem.self, TodoItem.self,
            configurations: config
        )
    }

    override func tearDown() { container = nil }

    func testPlannedRouteSurfacedForSelectedDay() throws {
        let trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        let photoRepo = SwiftDataPhotoRepository(context: container.mainContext)
        let planRepo = SwiftDataPlanRepository(context: container.mainContext)

        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)
        // 같은 날 계획 2개(좌표 있음) + 1개(좌표 없음)
        try planRepo.add(PlanItem(title: "A", plannedAt: base.addingTimeInterval(3600),
                                  latitude: 35.68, longitude: 139.76), to: trip)
        try planRepo.add(PlanItem(title: "B", plannedAt: base.addingTimeInterval(7200),
                                  latitude: 35.71, longitude: 139.80), to: trip)
        try planRepo.add(PlanItem(title: "메모만", plannedAt: base.addingTimeInterval(1800)), to: trip)

        let vm = MapViewModel(repository: trackRepo, photoRepository: photoRepo, planRepository: planRepo)
        vm.reload()

        // 계획이 있는 날이 조회 가능 날짜에 포함됨
        XCTAssertFalse(vm.availableDays.isEmpty)
        // 좌표 있는 2개가 시간순으로 계획 경로를 이룸
        XCTAssertEqual(vm.plannedRouteCoordinates.count, 2)
        XCTAssertEqual(vm.plannedStops.count, 2)
        XCTAssertEqual(vm.plannedRouteCoordinates.first?.latitude ?? 0, 35.68, accuracy: 1e-9)
    }
}
