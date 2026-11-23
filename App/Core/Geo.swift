import Foundation

/// 위경도 기반 순수 거리 계산. CoreLocation에 의존하지 않아 단위 테스트가 빠르고 결정적이다.
enum Geo {
    /// 지구 평균 반지름 (미터)
    static let earthRadius: Double = 6_371_000

    /// 두 좌표 사이의 대원 거리(Haversine), 미터.
    static func distance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a1 = sin(dLat / 2) * sin(dLat / 2)
        let a2 = cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let a = a1 + a2
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }

    static func distance(_ a: LocationSample, _ b: LocationSample) -> Double {
        distance(lat1: a.latitude, lon1: a.longitude, lat2: b.latitude, lon2: b.longitude)
    }

    /// 두 지점 사이 대권(great-circle) 경로를 count개 점으로 보간. (비행기 경로용)
    /// 구면 선형보간(slerp). 반환은 (위도, 경도) 좌표열.
    static func geodesic(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double,
        count: Int = 64
    ) -> [(latitude: Double, longitude: Double)] {
        let φ1 = lat1 * .pi / 180, λ1 = lon1 * .pi / 180
        let φ2 = lat2 * .pi / 180, λ2 = lon2 * .pi / 180
        // 단위 구 벡터
        let x1 = cos(φ1) * cos(λ1), y1 = cos(φ1) * sin(λ1), z1 = sin(φ1)
        let x2 = cos(φ2) * cos(λ2), y2 = cos(φ2) * sin(λ2), z2 = sin(φ2)
        let dot = max(-1, min(1, x1 * x2 + y1 * y2 + z1 * z2))
        let Ω = acos(dot)
        guard Ω > 1e-9 else { return [(lat1, lon1), (lat2, lon2)] }
        let sinΩ = sin(Ω)

        var result: [(latitude: Double, longitude: Double)] = []
        let n = max(count, 2)
        for i in 0...n {
            let t = Double(i) / Double(n)
            let a = sin((1 - t) * Ω) / sinΩ
            let b = sin(t * Ω) / sinΩ
            let x = a * x1 + b * x2
            let y = a * y1 + b * y2
            let z = a * z1 + b * z2
            let lat = atan2(z, (x * x + y * y).squareRoot()) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi
            result.append((lat, lon))
        }
        return result
    }
}
