import XCTest
import SwiftData
@testable import TravelTracker

@MainActor
final class PhotoRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var trackRepo: SwiftDataTrackRepository!
    var photoRepo: SwiftDataPhotoRepository!
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Trip.self, TrackPoint.self, Photo.self, Profile.self,
            configurations: config
        )
        trackRepo = SwiftDataTrackRepository(context: container.mainContext)
        photoRepo = SwiftDataPhotoRepository(context: container.mainContext)
    }

    override func tearDown() {
        container = nil; trackRepo = nil; photoRepo = nil
    }

    func makePhoto(_ offset: TimeInterval) -> Photo {
        Photo(filePath: "photos/a.jpg", thumbPath: "photos/a_thumb.jpg",
              latitude: 35.0, longitude: 139.0, takenAt: base.addingTimeInterval(offset))
    }

    func testAddAndFetchForTrip() throws {
        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)
        try photoRepo.add(makePhoto(10), to: trip)
        try photoRepo.add(makePhoto(5), to: trip)

        let photos = try photoRepo.photos(for: trip)
        XCTAssertEqual(photos.count, 2)
        // takenAt 오름차순
        XCTAssertEqual(photos[0].takenAt, base.addingTimeInterval(5))
        XCTAssertEqual(photos[1].takenAt, base.addingTimeInterval(10))
        XCTAssertEqual(photos[0].trip?.id, trip.id)
    }

    func testDelete() throws {
        let trip = try trackRepo.startTrip(name: "일본 여행", startDate: base, home: .default)
        let photo = makePhoto(0)
        try photoRepo.add(photo, to: trip)
        try photoRepo.delete(photo)
        XCTAssertEqual(try photoRepo.photos(for: trip).count, 0)
    }
}
