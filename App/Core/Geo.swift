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
}
