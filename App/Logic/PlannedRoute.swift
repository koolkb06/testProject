import Foundation

/// 좌표를 가진 계획 지점. PlanItem이 따른다.
protocol PlannedStop {
    var latitude: Double? { get }
    var longitude: Double? { get }
    var plannedAt: Date { get }
}

/// 계획 방문 경로: 좌표가 있는 일정을 시간 순서로 연결한 좌표열. (사용자 요청)
/// 실제 기록 경로(RoutePlayback)와 구분되는 "가야 할 길".
enum PlannedRoute {
    static func coordinates<T: PlannedStop>(_ stops: [T]) -> [RoutePlayback.Coord] {
        stops
            .filter { $0.latitude != nil && $0.longitude != nil }
            .sorted { $0.plannedAt < $1.plannedAt }
            .map { RoutePlayback.Coord(latitude: $0.latitude!, longitude: $0.longitude!) }
    }
}
