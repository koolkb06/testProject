import Foundation
import SwiftData

/// 여행 계획(타임라인) 항목 하나 = 하나의 이동 구간(출발 → 도착). (사용자 요청)
/// 출발지를 비우면 이전(더 이른 시간) 일정의 도착지가 출발지로 쓰인다(자동 체이닝).
@Model
final class PlanItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var plannedAt: Date
    var memo: String
    var isDone: Bool

    /// 이동 수단 raw("car"/"flight"/"transit"/"walk"). 옵셔널로 두어 기존 스토어와 호환.
    var transportRaw: String?
    var transport: LegTransport {
        get { LegTransport.from(transportRaw) }
        set { transportRaw = newValue.rawValue }
    }

    // 출발지(선택). 비우면 이전 일정 도착지로 대체.
    var fromPlaceName: String?
    var fromLatitude: Double?
    var fromLongitude: Double?

    // 도착지.
    var toPlaceName: String?
    var toLatitude: Double?
    var toLongitude: Double?

    var trip: Trip?

    init(
        id: UUID = UUID(),
        title: String,
        plannedAt: Date,
        memo: String = "",
        isDone: Bool = false,
        transportRaw: String? = nil,
        fromPlaceName: String? = nil,
        fromLatitude: Double? = nil,
        fromLongitude: Double? = nil,
        toPlaceName: String? = nil,
        toLatitude: Double? = nil,
        toLongitude: Double? = nil,
        trip: Trip? = nil
    ) {
        self.id = id
        self.title = title
        self.plannedAt = plannedAt
        self.memo = memo
        self.isDone = isDone
        self.transportRaw = transportRaw
        self.fromPlaceName = fromPlaceName
        self.fromLatitude = fromLatitude
        self.fromLongitude = fromLongitude
        self.toPlaceName = toPlaceName
        self.toLatitude = toLatitude
        self.toLongitude = toLongitude
        self.trip = trip
    }
}
