import Foundation

/// 지도 표시 영역. MapKit에 의존하지 않는 값 타입이라 테스트 가능.
/// 뷰에서 MKCoordinateRegion으로 변환해 사용한다.
struct RegionBox: Equatable {
    var centerLatitude: Double
    var centerLongitude: Double
    var latitudeDelta: Double
    var longitudeDelta: Double
}

enum RegionCalculator {
    /// 점들을 모두 담는 영역. padding으로 여백을 주고, minDelta로 최소 확대 한계를 둔다.
    static func bounding<T: GeoTimed>(
        _ pts: [T],
        padding: Double = 1.4,
        minDelta: Double = 0.005
    ) -> RegionBox? {
        guard !pts.isEmpty else { return nil }
        let lats = pts.map(\.latitude)
        let lons = pts.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        return RegionBox(
            centerLatitude: (minLat + maxLat) / 2,
            centerLongitude: (minLon + maxLon) / 2,
            latitudeDelta: max((maxLat - minLat) * padding, minDelta),
            longitudeDelta: max((maxLon - minLon) * padding, minDelta)
        )
    }
}
