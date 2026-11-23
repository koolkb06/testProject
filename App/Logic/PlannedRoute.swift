import Foundation

/// 출발·도착 좌표를 가진 계획 구간의 소스. PlanItem이 따른다.
protocol PlannedLegSource {
    var fromLatitude: Double? { get }
    var fromLongitude: Double? { get }
    var toLatitude: Double? { get }
    var toLongitude: Double? { get }
    var plannedAt: Date { get }
    var title: String { get }
    var isDone: Bool { get }
    var transport: LegTransport { get }
}

/// 그려질 이동 구간(출발→도착).
struct PlannedLeg: Equatable {
    let from: RoutePlayback.Coord
    let to: RoutePlayback.Coord
    let order: Int
    let transport: LegTransport
}

/// 도착 지점 마커.
struct PlannedStop: Equatable {
    let coord: RoutePlayback.Coord
    let order: Int
    let title: String
    let isDone: Bool
}

struct PlannedRouteResult: Equatable {
    let legs: [PlannedLeg]
    let stops: [PlannedStop]
}

/// 계획 방문 경로 구성. (사용자 요청)
/// - 시간순 정렬.
/// - 도착지 좌표가 있는 항목만 "정류장"으로 번호를 받는다.
/// - 각 항목의 출발지는 명시값, 없으면 이전 정류장의 도착지(자동 체이닝).
/// - 출발지가 정해진 경우에만 from→to 선(leg)을 만든다.
enum PlannedRoute {
    static func build<T: PlannedLegSource>(_ items: [T]) -> PlannedRouteResult {
        let sorted = items.sorted { $0.plannedAt < $1.plannedAt }
        var legs: [PlannedLeg] = []
        var stops: [PlannedStop] = []
        var prevTo: RoutePlayback.Coord?
        var order = 0

        for item in sorted {
            guard let to = coord(item.toLatitude, item.toLongitude) else { continue }
            order += 1
            stops.append(PlannedStop(coord: to, order: order, title: item.title, isDone: item.isDone))
            let from = coord(item.fromLatitude, item.fromLongitude) ?? prevTo
            if let from {
                legs.append(PlannedLeg(from: from, to: to, order: order, transport: item.transport))
            }
            prevTo = to
        }
        return PlannedRouteResult(legs: legs, stops: stops)
    }

    private static func coord(_ lat: Double?, _ lon: Double?) -> RoutePlayback.Coord? {
        guard let lat, let lon else { return nil }
        return RoutePlayback.Coord(latitude: lat, longitude: lon)
    }
}
