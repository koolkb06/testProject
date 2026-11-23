import XCTest
@testable import TravelTracker

final class SegmentSplitterTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func s(_ offset: TimeInterval) -> LocationSample {
        LocationSample(latitude: 37, longitude: 127, horizontalAccuracy: 5,
                       timestamp: base.addingTimeInterval(offset))
    }

    func testEmpty() {
        XCTAssertTrue(SegmentSplitter().split([]).isEmpty)
    }

    func testSingleSegmentWhenGapsSmall() {
        let splitter = SegmentSplitter(maxTimeGap: 180)
        let pts = [s(0), s(60), s(120), s(180)]
        let segs = splitter.split(pts)
        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].count, 4)
    }

    func testSplitsOnLargeGap() {
        let splitter = SegmentSplitter(maxTimeGap: 180)
        // 0,60 (연속) → 600초 점프(지하철) → 660,720
        let pts = [s(0), s(60), s(600), s(660), s(720)]
        let segs = splitter.split(pts)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].count, 2)
        XCTAssertEqual(segs[1].count, 3)
    }

    func testGapExactlyAtThresholdDoesNotSplit() {
        let splitter = SegmentSplitter(maxTimeGap: 180)
        let pts = [s(0), s(180)] // 간격 == 임계치 → 끊지 않음(초과만 끊음)
        XCTAssertEqual(splitter.split(pts).count, 1)
    }
}
