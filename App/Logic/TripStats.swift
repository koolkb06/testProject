import Foundation

/// 하루(또는 한 구간)의 이동 통계. (설계 §3 정보 pill: 오늘 이동 거리·시간)
struct TripStats: Equatable {
    var distanceMeters: Double
    var duration: TimeInterval

    static let zero = TripStats(distanceMeters: 0, duration: 0)
}

enum StatsCalculator {
    /// 시간순 점들의 총 이동 거리와 전체 소요 시간.
    /// 거리는 연속 점 사이 거리의 합, 시간은 (마지막 - 처음).
    static func stats<T: GeoTimed>(_ pts: [T]) -> TripStats {
        guard pts.count >= 2 else { return .zero }
        var distance = 0.0
        for i in 1..<pts.count {
            distance += Geo.distance(
                lat1: pts[i - 1].latitude, lon1: pts[i - 1].longitude,
                lat2: pts[i].latitude, lon2: pts[i].longitude
            )
        }
        let duration = pts.last!.timestamp.timeIntervalSince(pts.first!.timestamp)
        return TripStats(distanceMeters: distance, duration: max(0, duration))
    }
}
