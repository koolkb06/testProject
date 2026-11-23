import Foundation

/// 시간순 점들을 segment(끊어 그릴 선 조각)로 분리한다. (설계 §2)
/// 연속한 두 점의 시간 간격이 maxTimeGap을 넘으면(지하철 등) 선을 끊는다.
///
/// 제네릭이라 TrackPoint, LocationSample 등 timestamp를 가진 어떤 타입에도 쓸 수 있고,
/// SwiftData 없이 단위 테스트할 수 있다.
struct SegmentSplitter {
    /// segment를 끊는 시간 간격(초).
    var maxTimeGap: TimeInterval = 180

    func split<T>(_ items: [T], timestamp: (T) -> Date) -> [[T]] {
        guard !items.isEmpty else { return [] }

        var segments: [[T]] = []
        var current: [T] = [items[0]]

        for i in 1..<items.count {
            let gap = timestamp(items[i]).timeIntervalSince(timestamp(items[i - 1]))
            if gap > maxTimeGap {
                segments.append(current)
                current = [items[i]]
            } else {
                current.append(items[i])
            }
        }
        segments.append(current)
        return segments
    }
}

extension SegmentSplitter {
    func split(_ samples: [LocationSample]) -> [[LocationSample]] {
        split(samples, timestamp: { $0.timestamp })
    }
}
