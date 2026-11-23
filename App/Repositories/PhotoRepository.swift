import Foundation
import SwiftData

/// 사진 저장소. SwiftData를 감춰 테스트에서 in-memory 컨테이너로 대체 가능.
protocol PhotoRepository {
    func add(_ photo: Photo, to trip: Trip) throws
    func photos(for trip: Trip) throws -> [Photo]
    func delete(_ photo: Photo) throws
}

final class SwiftDataPhotoRepository: PhotoRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ photo: Photo, to trip: Trip) throws {
        photo.trip = trip
        context.insert(photo)
        try context.save()
    }

    func photos(for trip: Trip) throws -> [Photo] {
        let tripID = trip.id
        let descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { $0.trip?.id == tripID },
            sortBy: [SortDescriptor(\.takenAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ photo: Photo) throws {
        context.delete(photo)
        try context.save()
    }
}
