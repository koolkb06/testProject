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
        // 같은 날: 출발 지정 구간 + 출발 비운 구간(자동 체이닝) + 도착 없는 항목
        try planRepo.add(PlanItem(title: "A", plannedAt: base.addingTimeInterval(3600),
                                  fromLatitude: 35.68, fromLongitude: 139.76,
                                  toLatitude: 35.71, toLongitude: 139.80), to: trip)
        try planRepo.add(PlanItem(title: "B", plannedAt: base.addingTimeInterval(7200),
                                  toLatitude: 35.72, toLongitude: 139.81), to: trip)
        try planRepo.add(PlanItem(title: "메모만", plannedAt: base.addingTimeInterval(1800)), to: trip)

        let vm = MapViewModel(repository: trackRepo, photoRepository: photoRepo, planRepository: planRepo)
        vm.reload()

        // 계획이 있는 날이 조회 가능 날짜에 포함됨
        XCTAssertFalse(vm.availableDays.isEmpty)
        let route = vm.plannedRoute
        XCTAssertEqual(route.stops.count, 2)   // 도착 있는 2개
        XCTAssertEqual(route.legs.count, 2)    // A: 명시 출발, B: 이전 도착(35.71,139.80)에서 체이닝
        XCTAssertEqual(route.legs[1].from, .init(latitude: 35.71, longitude: 139.80))
    }
}
