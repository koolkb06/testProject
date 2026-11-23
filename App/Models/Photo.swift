import Foundation
import SwiftData

/// 촬영 사진. 3단계(카메라)에서 사용. 현재는 스키마 등록 목적으로만 정의.
@Model
final class Photo {
    @Attribute(.unique) var id: UUID
    var filePath: String
    var thumbPath: String
    var latitude: Double
    var longitude: Double
    var takenAt: Date

    var trip: Trip?

    init(
        id: UUID = UUID(),
        filePath: String,
        thumbPath: String,
        latitude: Double,
        longitude: Double,
        takenAt: Date,
        trip: Trip? = nil
    ) {
        self.id = id
        self.filePath = filePath
        self.thumbPath = thumbPath
        self.latitude = latitude
        self.longitude = longitude
        self.takenAt = takenAt
        self.trip = trip
    }
}
