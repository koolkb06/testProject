import XCTest
@testable import TravelTracker

final class RoutePlaybackTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    // 경도 0 고정, 위도만 증가하는 직선 경로
    func line() -> [LocationSample] {
        (0...4).map { i in
            LocationSample(latitude: 37.0 + Double(i) * 0.001, longitude: 127.0,
                           horizontalAccuracy: 5, timestamp: base.addingTimeInterval(Double(i) * 10))
        }
    }

    func testPositionAtEnds() {
        let pts = line()
        let start = RoutePlayback.position(pts, progress: 0)
        XCTAssertEqual(start?.latitude ?? 0, 37.0, accuracy: 1e-9)
        let end = RoutePlayback.position(pts, progress: 1)
        XCTAssertEqual(end?.latitude ?? 0, 37.004, accuracy: 1e-9)
    }

    func testPositionMidpoint() {
        let pts = line()
        let mid = RoutePlayback.position(pts, progress: 0.5)
        // 직선 등간격이라 중앙 ≈ 37.002
        XCTAssertEqual(mid?.latitude ?? 0, 37.002, accuracy: 1e-6)
    }

    func testProgressClampsOutOfRange() {
        let pts = line()
        XCTAssertEqual(RoutePlayback.position(pts, progress: -5)?.latitude ?? 0, 37.0, accuracy: 1e-9)
        XCTAssertEqual(RoutePlayback.position(pts, progress: 5)?.latitude ?? 0, 37.004, accuracy: 1e-9)
    }

    func testDrawnCoordinatesGrowWithProgress() {
        let pts = line()
        XCTAssertEqual(RoutePlayback.drawnCoordinates(pts, progress: 0).count, 1)
        let full = RoutePlayback.drawnCoordinates(pts, progress: 1)
        XCTAssertEqual(full.count, pts.count)
        // 절반 진행: 시작점 + 중간까지 점들 + 보간 머리
        let half = RoutePlayback.drawnCoordinates(pts, progress: 0.5)
        XCTAssertGreaterThan(half.count, 1)
        XCTAssertLessThan(half.count, full.count)
        // 머리는 중앙 근처
        XCTAssertEqual(half.last?.latitude ?? 0, 37.002, accuracy: 1e-6)
    }

    func testEmpty() {
        XCTAssertNil(RoutePlayback.position([LocationSample](), progress: 0.5))
        XCTAssertTrue(RoutePlayback.drawnCoordinates([LocationSample](), progress: 0.5).isEmpty)
    }
}
