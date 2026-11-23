import Foundation
import SwiftData

/// 여행 계획(타임라인) 항목 하나. 날짜·시간별 일정. (사용자 요청)
@Model
final class PlanItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var plannedAt: Date
    var placeName: String?
    var latitude: Double?
    var longitude: Double?
    var memo: String
    var isDone: Bool

    var trip: Trip?

    init(
        id: UUID = UUID(),
        title: String,
        plannedAt: Date,
        placeName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        memo: String = "",
        isDone: Bool = false,
        trip: Trip? = nil
    ) {
        self.id = id
        self.title = title
        self.plannedAt = plannedAt
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
        self.memo = memo
        self.isDone = isDone
        self.trip = trip
    }
}
