import XCTest
import SwiftData
@testable import TravelTracker

@MainActor
final class MapViewModelPlaybackTests: XCTestCase {
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

    private func makeViewModel() throws -> MapViewModel {
        let trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        let photoRepo = SwiftDataPhotoRepository(context: container.mainContext)
        let planRepo = SwiftDataPlanRepository(context: container.mainContext)

        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)
        try trackRepo.append(LocationSample(latitude: 35.6580, longitude: 139.7016,
                                            horizontalAccuracy: 5, timestamp: base.addingTimeInterval(60)), to: trip)
        try trackRepo.append(LocationSample(latitude: 35.6702, longitude: 139.7027,
                                            horizontalAccuracy: 5, timestamp: base.addingTimeInterval(600)), to: trip)
        try planRepo.add(PlanItem(title: "이동", plannedAt: base.addingTimeInterval(900),
                                  fromLatitude: 35.68, fromLongitude: 139.76,
                                  toLatitude: 35.71, toLongitude: 139.80), to: trip)

        let vm = MapViewModel(repository: trackRepo, photoRepository: photoRepo, planRepository: planRepo)
        vm.reload()
        return vm
    }

    func testStopAllPlaybackStopsTrackPlayback() throws {
        let vm = try makeViewModel()
        vm.play()
        XCTAssertTrue(vm.isPlaying)

        vm.stopAllPlayback()

        XCTAssertFalse(vm.isPlaying)
        XCTAssertEqual(vm.playbackProgress, 1)   // 전체 경로 표시로 복귀
    }

    func testStopAllPlaybackStopsPlannedPlayback() throws {
        let vm = try makeViewModel()
        vm.playPlanned()
        XCTAssertTrue(vm.isPlayingPlanned)

        vm.stopAllPlayback()

        XCTAssertFalse(vm.isPlayingPlanned)
        XCTAssertEqual(vm.plannedProgress, 0)
    }

    func testStopAllPlaybackWhenIdleIsHarmless() throws {
        let vm = try makeViewModel()
        vm.stopAllPlayback()

        XCTAssertFalse(vm.isPlaying)
        XCTAssertFalse(vm.isPlayingPlanned)
    }
}
