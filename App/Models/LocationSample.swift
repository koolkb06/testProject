import Foundation

/// 위치 1회 측정값. 순수 value type이며 CoreLocation에 의존하지 않는다.
/// 위치 파이프라인(Service → Recorder → Filter)은 이 타입으로 흐르고,
/// 저장 시점에만 `TrackPoint`(@Model)로 변환된다.
struct LocationSample: Equatable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    /// 수평 정확도(미터). 음수면 좌표 무효(CoreLocation 규약).
    var horizontalAccuracy: Double
    /// 속도(m/s). 음수면 미측정.
    var speed: Double
    var timestamp: Date

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        horizontalAccuracy: Double,
        speed: Double = -1,
        timestamp: Date
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.timestamp = timestamp
    }
}
