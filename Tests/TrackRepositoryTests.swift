import XCTest
import SwiftData
@testable import TravelTracker

@MainActor
final class TrackRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var repo: SwiftDataTrackRepository!
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Trip.self, TrackPoint.self, Photo.self, Profile.self,
            configurations: config
        )
        repo = SwiftDataTrackRepository(context: container.mainContext)
    }

    override func tearDown() {
        container = nil
        repo = nil
    }

    func testStartTripRecordsHomeAddress() throws {
        let home = HomeLocation(address: "탄천상로 6", latitude: nil, longitude: nil)
        let trip = try repo.startTrip(name: "일본 여행", startDate: base, home: home)
        XCTAssertEqual(trip.startAddress, "탄천상로 6")
        // 좌표 없으면 seed 점 없음
        XCTAssertEqual(try repo.points(for: trip).count, 0)
    }

    func testStartTripSeedsHomePointWhenCoordinateKnown() throws {
        let home = HomeLocation(address: "탄천상로 6", latitude: 37.4, longitude: 127.1)
        let trip = try repo.startTrip(name: "일본 여행", startDate: base, home: home)
        let pts = try repo.points(for: trip)
        XCTAssertEqual(pts.count, 1)
        XCTAssertEqual(pts.first?.latitude, 37.4)
        XCTAssertEqual(pts.first?.longitude, 127.1)
    }

    func testActiveTripReturnsOngoing() throws {
        XCTAssertNil(try repo.activeTrip())
        let trip = try repo.startTrip(name: "일본 여행", startDate: base, home: .default)
        XCTAssertEqual(try repo.activeTrip()?.id, trip.id)
        try repo.endTrip(trip, endDate: base.addingTimeInterval(3600))
        XCTAssertNil(try repo.activeTrip())
    }

    func testAppendAndFetchOrdered() throws {
        let trip = try repo.startTrip(name: "일본 여행", startDate: base, home: .default)
        try repo.append(LocationSample(latitude: 37.0, longitude: 127.0,
                                       horizontalAccuracy: 5, timestamp: base.addingTimeInterval(20)),
                        to: trip)
        try repo.append(LocationSample(latitude: 37.1, longitude: 127.0,
                                       horizontalAccuracy: 5, timestamp: base.addingTimeInterval(10)),
                        to: trip)
        let pts = try repo.points(for: trip)
        XCTAssertEqual(pts.count, 2)
        // 시간 오름차순 정렬 확인
        XCTAssertEqual(pts[0].timestamp, base.addingTimeInterval(10))
        XCTAssertEqual(pts[1].timestamp, base.addingTimeInterval(20))
    }
}
