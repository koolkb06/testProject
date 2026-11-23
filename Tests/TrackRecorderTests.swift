import XCTest
import SwiftData
import CoreLocation
@testable import TravelTracker

@MainActor
final class TrackRecorderTests: XCTestCase {
    var container: ModelContainer!
    var repo: SwiftDataTrackRepository!
    var mock: MockLocationService!
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Trip.self, TrackPoint.self, Photo.self, Profile.self,
            configurations: config
        )
        repo = SwiftDataTrackRepository(context: container.mainContext)
        mock = MockLocationService()
    }

    override func tearDown() {
        container = nil; repo = nil; mock = nil
    }

    func makeRecorder(home: HomeLocation = HomeLocation(address: "탄천상로 6", latitude: nil, longitude: nil)) -> TrackRecorder {
        TrackRecorder(locationService: mock, repository: repo,
                      filter: TrackPointFilter(maxAccuracy: 100, minDistance: 20),
                      home: home)
    }

    func sample(lat: Double, lon: Double, acc: Double = 5, offset: TimeInterval) -> LocationSample {
        LocationSample(latitude: lat, longitude: lon, horizontalAccuracy: acc,
                       timestamp: base.addingTimeInterval(offset))
    }

    func testStartBeginsRecordingAndStartsService() {
        let r = makeRecorder()
        r.start(tripName: "일본 여행", now: base)
        XCTAssertTrue(r.isRecording)
        XCTAssertTrue(mock.started)
    }

    func testSamplesIgnoredBeforeStart() {
        let r = makeRecorder()
        mock.emit(sample(lat: 37, lon: 127, offset: 0))
        XCTAssertEqual(r.pointCount, 0)
    }

    func testAcceptedSamplesArePersisted() throws {
        let r = makeRecorder()
        r.start(tripName: "일본 여행", now: base)

        mock.emit(sample(lat: 37.0000, lon: 127.0, offset: 0))     // 첫 점 수용
        mock.emit(sample(lat: 37.0001, lon: 127.0, offset: 10))    // ~11m, 20m 미만 → 버림
        mock.emit(sample(lat: 37.0005, lon: 127.0, offset: 20))    // ~55m → 수용

        XCTAssertEqual(r.pointCount, 2)

        let trip = try XCTUnwrap(repo.activeTrip())
        XCTAssertEqual(try repo.points(for: trip).count, 2)
    }

    func testPoorAccuracySampleRejected() {
        let r = makeRecorder()
        r.start(tripName: "일본 여행", now: base)
        mock.emit(sample(lat: 37, lon: 127, acc: 250, offset: 0)) // 정확도 불량
        XCTAssertEqual(r.pointCount, 0)
    }

    func testStartSeedsHomePointWhenCoordinateKnown() throws {
        let r = makeRecorder(home: HomeLocation(address: "탄천상로 6", latitude: 37.4, longitude: 127.1))
        r.start(tripName: "일본 여행", now: base)
        // 집 좌표 seed 1개가 이미 기록됨
        XCTAssertEqual(r.pointCount, 1)

        // 집에서 충분히 떨어진 다음 점은 수용
        mock.emit(sample(lat: 37.41, lon: 127.1, offset: 60))
        XCTAssertEqual(r.pointCount, 2)
    }

    func testStopEndsTrip() throws {
        let r = makeRecorder()
        r.start(tripName: "일본 여행", now: base)
        XCTAssertNotNil(try repo.activeTrip())
        r.stop(now: base.addingTimeInterval(3600))
        XCTAssertFalse(r.isRecording)
        XCTAssertFalse(mock.started)
        XCTAssertNil(try repo.activeTrip())
    }

    func testAuthorizationChangePropagates() {
        let r = makeRecorder()
        mock.changeAuthorization(.denied)
        XCTAssertEqual(r.authorizationStatus, .denied)
    }
}
