import Foundation
import SwiftData

/// 하나의 여행. 경로 점(TrackPoint)들을 자식으로 가진다.
@Model
final class Trip {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?

    /// 여행 시작점(집). 좌표는 미확정일 수 있어 주소만 기록될 수 있다. (설계: 집=탄천상로 6)
    var startAddress: String?
    var startLatitude: Double?
    var startLongitude: Double?

    @Relationship(deleteRule: .cascade, inverse: \TrackPoint.trip)
    var points: [TrackPoint]

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date? = nil,
        startAddress: String? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.startAddress = startAddress
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.points = []
    }
}
