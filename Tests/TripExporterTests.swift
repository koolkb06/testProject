import XCTest
@testable import TravelTracker

final class TripExporterTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    func pt(_ lat: Double, _ lon: Double, _ offset: TimeInterval) -> LocationSample {
        LocationSample(latitude: lat, longitude: lon, altitude: 0,
                       horizontalAccuracy: 5, timestamp: base.addingTimeInterval(offset))
    }

    func testGPXStructureAndCoordinates() {
        let segments = [[pt(37.1, 127.1, 0), pt(37.2, 127.2, 10)]]
        let gpx = TripExporter.content(trackName: "일본 여행", segments: segments, waypoints: [], format: .gpx)
        XCTAssertTrue(gpx.hasPrefix("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
        XCTAssertTrue(gpx.contains("<trkseg>"))
        XCTAssertTrue(gpx.contains("lat=\"37.100000\""))
        XCTAssertTrue(gpx.contains("lon=\"127.200000\""))
        XCTAssertTrue(gpx.contains("<time>"))
        XCTAssertTrue(gpx.contains("</gpx>"))
    }

    func testGPXMultipleSegments() {
        let segments = [[pt(37.1, 127.1, 0)], [pt(37.5, 127.5, 600)]]
        let gpx = TripExporter.content(trackName: "t", segments: segments, waypoints: [], format: .gpx)
        // trkseg가 2개
        XCTAssertEqual(gpx.components(separatedBy: "<trkseg>").count - 1, 2)
    }

    func testGPXWaypoint() {
        let wp = [Waypoint(name: "사진", latitude: 37.3, longitude: 127.3, time: base)]
        let gpx = TripExporter.content(trackName: "t", segments: [[pt(37.1, 127.1, 0)]], waypoints: wp, format: .gpx)
        XCTAssertTrue(gpx.contains("<wpt lat=\"37.300000\" lon=\"127.300000\">"))
        XCTAssertTrue(gpx.contains("<name>사진</name>"))
    }

    func testKMLStructureCoordinatesLonLatOrder() {
        let segments = [[pt(37.1, 127.1, 0), pt(37.2, 127.2, 10)]]
        let kml = TripExporter.content(trackName: "t", segments: segments, waypoints: [], format: .kml)
        XCTAssertTrue(kml.contains("<kml"))
        XCTAssertTrue(kml.contains("<LineString>"))
        // KML은 경도,위도,고도 순
        XCTAssertTrue(kml.contains("127.100000,37.100000,0"))
        XCTAssertTrue(kml.contains("</kml>"))
    }

    func testXMLEscapingInName() {
        let gpx = TripExporter.content(trackName: "A & B <여행>", segments: [[pt(37, 127, 0)]], waypoints: [], format: .gpx)
        XCTAssertTrue(gpx.contains("A &amp; B &lt;여행&gt;"))
        XCTAssertFalse(gpx.contains("A & B <여행>"))
    }

    func testWriteCreatesFileWithExtension() throws {
        let url = try TripExporter.write("hello", baseName: "일본 여행", format: .kml)
        XCTAssertEqual(url.pathExtension, "kml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "hello")
        try? FileManager.default.removeItem(at: url)
    }
}
