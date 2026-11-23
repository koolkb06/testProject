import XCTest
import SwiftData
@testable import TravelTracker

@MainActor
final class PlanTodoRepositoryTests: XCTestCase {
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

    // MARK: - Plan

    func testPlanAddFetchSortedByTime() throws {
        let trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        let planRepo = SwiftDataPlanRepository(context: container.mainContext)
        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)

        try planRepo.add(PlanItem(title: "저녁", plannedAt: base.addingTimeInterval(7200)), to: trip)
        try planRepo.add(PlanItem(title: "점심", plannedAt: base.addingTimeInterval(3600)), to: trip)

        let items = try planRepo.items(for: trip)
        XCTAssertEqual(items.map(\.title), ["점심", "저녁"])
        XCTAssertEqual(items.first?.trip?.id, trip.id)
    }

    func testPlanEditAndDelete() throws {
        let trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        let planRepo = SwiftDataPlanRepository(context: container.mainContext)
        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)

        let item = PlanItem(title: "원제목", plannedAt: base)
        try planRepo.add(item, to: trip)
        item.title = "수정됨"
        item.isDone = true
        try planRepo.save()
        XCTAssertEqual(try planRepo.items(for: trip).first?.title, "수정됨")
        XCTAssertEqual(try planRepo.items(for: trip).first?.isDone, true)

        try planRepo.delete(item)
        XCTAssertEqual(try planRepo.items(for: trip).count, 0)
    }

    // MARK: - Todo

    func testTodoAddToggleDelete() throws {
        let todoRepo = SwiftDataTodoRepository(context: container.mainContext)
        let todo = TodoItem(title: "여권 챙기기", createdAt: base)
        try todoRepo.add(todo)
        XCTAssertEqual(try todoRepo.all().count, 1)

        todo.isDone = true
        try todoRepo.save()
        XCTAssertEqual(try todoRepo.all().first?.isDone, true)

        try todoRepo.delete(todo)
        XCTAssertEqual(try todoRepo.all().count, 0)
    }
}
