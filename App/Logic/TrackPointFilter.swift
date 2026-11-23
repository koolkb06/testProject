import Foundation

/// 새 위치 샘플을 저장할지 결정하는 순수 필터. (설계 §2)
/// - 정확도가 나쁜 점(오차 maxAccuracy 초과, 또는 음수=무효)은 버린다.
/// - 직전 저장점에서 minDistance 미만으로 움직였으면 버린다.
struct TrackPointFilter {
    /// 허용 최대 수평 정확도(미터). 초과하면 버림.
    var maxAccuracy: Double = 100
    /// 직전 저장점과의 최소 이동 거리(미터).
    var minDistance: Double = 20

    func shouldAccept(_ sample: LocationSample, lastAccepted: LocationSample?) -> Bool {
        // 정확도 무효/불량 → 버림
        guard sample.horizontalAccuracy >= 0,
              sample.horizontalAccuracy <= maxAccuracy else {
            return false
        }
        // 첫 점은 항상 수용
        guard let last = lastAccepted else { return true }
        // 충분히 이동했을 때만 수용
        return Geo.distance(last, sample) >= minDistance
    }
}
