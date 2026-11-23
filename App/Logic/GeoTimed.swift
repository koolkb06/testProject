import Foundation

/// 위경도 + 시각을 가진 점. LocationSample(값 타입)과 TrackPoint(@Model)가 모두 따른다.
/// 지도/통계 로직을 두 타입 모두에서, 그리고 SwiftData 없이 테스트할 수 있게 해준다.
protocol GeoTimed {
    var latitude: Double { get }
    var longitude: Double { get }
    var timestamp: Date { get }
}

extension LocationSample: GeoTimed {}
extension TrackPoint: GeoTimed {}
