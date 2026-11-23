import Foundation

/// 경로 재생 보간. (설계 §3 애니메이션: 선이 출발점부터 그려지고 마커가 따라 이동)
/// 거리 기준으로 진행도 0...1을 좌표로 변환하는 순수 로직.
enum RoutePlayback {
    struct Coord: Equatable {
        var latitude: Double
        var longitude: Double
    }

    /// 누적 거리 기준 진행도 위치. progress는 0...1로 clamp.
    static func position<T: GeoTimed>(_ pts: [T], progress: Double) -> Coord? {
        guard let first = pts.first else { return nil }
        guard pts.count > 1 else {
            return Coord(latitude: first.latitude, longitude: first.longitude)
        }
        let p = clamp(progress)
        let (cum, total) = cumulative(pts)
        guard total > 0 else {
            return Coord(latitude: first.latitude, longitude: first.longitude)
        }
        let target = p * total
        for i in 1..<pts.count where cum[i] >= target {
            let segLen = cum[i] - cum[i - 1]
            let t = segLen == 0 ? 0 : (target - cum[i - 1]) / segLen
            return Coord(
                latitude: pts[i - 1].latitude + (pts[i].latitude - pts[i - 1].latitude) * t,
                longitude: pts[i - 1].longitude + (pts[i].longitude - pts[i - 1].longitude) * t
            )
        }
        return Coord(latitude: pts.last!.latitude, longitude: pts.last!.longitude)
    }

    /// 진행도까지 그려진 폴리라인 좌표들(부분 그리기용). 마지막은 보간된 머리 위치.
    static func drawnCoordinates<T: GeoTimed>(_ pts: [T], progress: Double) -> [Coord] {
        guard let first = pts.first else { return [] }
        guard pts.count > 1 else {
            return [Coord(latitude: first.latitude, longitude: first.longitude)]
        }
        let p = clamp(progress)
        let (cum, total) = cumulative(pts)
        guard total > 0 else {
            return [Coord(latitude: first.latitude, longitude: first.longitude)]
        }
        let target = p * total

        var result = [Coord(latitude: first.latitude, longitude: first.longitude)]
        for i in 1..<pts.count {
            if cum[i] <= target {
                result.append(Coord(latitude: pts[i].latitude, longitude: pts[i].longitude))
            } else {
                if let head = position(pts, progress: p), result.last != head {
                    result.append(head)
                }
                break
            }
        }
        return result
    }

    // MARK: - Helpers

    private static func clamp(_ v: Double) -> Double { min(max(v, 0), 1) }

    private static func cumulative<T: GeoTimed>(_ pts: [T]) -> (cum: [Double], total: Double) {
        var cum = [0.0]
        var total = 0.0
        for i in 1..<pts.count {
            total += Geo.distance(
                lat1: pts[i - 1].latitude, lon1: pts[i - 1].longitude,
                lat2: pts[i].latitude, lon2: pts[i].longitude
            )
            cum.append(total)
        }
        return (cum, total)
    }
}
