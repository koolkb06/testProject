import XCTest
import SwiftData
@testable import TravelTracker

@MainActor
final class MapViewModelExportTests: XCTestCase {
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

    func testExportURLProducesValidGPXFile() throws {
        let trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        let photoRepo = SwiftDataPhotoRepository(context: container.mainContext)

        // 집 좌표 seed(1) + 추가 점(2) = 3점
        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)
        try trackRepo.append(LocationSample(latitude: 37.34, longitude: 127.11,
                                            horizontalAccuracy: 5, timestamp: base.addingTimeInterval(60)), to: trip)
        try trackRepo.append(LocationSample(latitude: 37.36, longitude: 127.13,
                                            horizontalAccuracy: 5, timestamp: base.addingTimeInterval(120)), to: trip)

        let planRepo = SwiftDataPlanRepository(context: container.mainContext)
        let vm = MapViewModel(repository: trackRepo, photoRepository: photoRepo, planRepository: planRepo)
        vm.reload()

        let url = try XCTUnwrap(vm.exportURL(format: .gpx))
        XCTAssertEqual(url.pathExtension, "gpx")
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("<gpx"))
        XCTAssertTrue(content.contains("<trkpt"))
        // 집 좌표가 포함되어야 함(37.332388, 127.112209)
        XCTAssertTrue(content.contains("lat=\"37.332388\""))
        try? FileManager.default.removeItem(at: url)
    }

    func testExportWithNoTripReturnsNil() throws {
        let trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        let photoRepo = SwiftDataPhotoRepository(context: container.mainContext)
        let planRepo = SwiftDataPlanRepository(context: container.mainContext)
        let vm = MapViewModel(repository: trackRepo, photoRepository: photoRepo, planRepository: planRepo)
        vm.reload()
        XCTAssertNil(vm.exportURL(format: .kml))
    }
}
