import Foundation

/// 내보내기 포맷.
enum ExportFormat {
    case gpx, kml

    var fileExtension: String { self == .gpx ? "gpx" : "kml" }
    var mimeType: String { self == .gpx ? "application/gpx+xml" : "application/vnd.google-earth.kml+xml" }
}

/// 내보낼 지점(사진 등 waypoint).
struct Waypoint {
    var name: String
    var latitude: Double
    var longitude: Double
    var time: Date?
}

/// 경로 + waypoint를 GPX/KML 문자열로 만드는 순수 생성기. (설계 §5)
/// segments는 끊긴 선 조각들(SegmentSplitter 결과). GeoTimed라 TrackPoint/LocationSample 모두 가능.
enum TripExporter {

    static func content<T: GeoTimed>(
        trackName: String,
        segments: [[T]],
        waypoints: [Waypoint],
        format: ExportFormat
    ) -> String {
        switch format {
        case .gpx: return gpx(trackName: trackName, segments: segments, waypoints: waypoints)
        case .kml: return kml(trackName: trackName, segments: segments, waypoints: waypoints)
        }
    }

    /// 임시 파일로 써서 공유용 URL 반환.
    static func write(_ content: String, baseName: String, format: ExportFormat) throws -> URL {
        let safe = baseName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safe).\(format.fileExtension)")
        try content.data(using: .utf8)?.write(to: url)
        return url
    }

    // MARK: - GPX

    private static func gpx<T: GeoTimed>(trackName: String, segments: [[T]], waypoints: [Waypoint]) -> String {
        var s = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="TravelTracker" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata><name>\(esc(trackName))</name></metadata>

        """
        for w in waypoints {
            s += "  <wpt lat=\"\(coord(w.latitude))\" lon=\"\(coord(w.longitude))\">\n"
            if let t = w.time { s += "    <time>\(iso(t))</time>\n" }
            s += "    <name>\(esc(w.name))</name>\n  </wpt>\n"
        }
        s += "  <trk><name>\(esc(trackName))</name>\n"
        for seg in segments {
            s += "    <trkseg>\n"
            for p in seg {
                s += "      <trkpt lat=\"\(coord(p.latitude))\" lon=\"\(coord(p.longitude))\">"
                s += "<time>\(iso(p.timestamp))</time></trkpt>\n"
            }
            s += "    </trkseg>\n"
        }
        s += "  </trk>\n</gpx>\n"
        return s
    }

    // MARK: - KML

    private static func kml<T: GeoTimed>(trackName: String, segments: [[T]], waypoints: [Waypoint]) -> String {
        var s = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <name>\(esc(trackName))</name>

        """
        for (i, seg) in segments.enumerated() {
            let coords = seg.map { "\(coord($0.longitude)),\(coord($0.latitude)),0" }.joined(separator: " ")
            s += """
              <Placemark>
                <name>\(esc(trackName)) 경로 \(i + 1)</name>
                <LineString><tessellate>1</tessellate><coordinates>\(coords)</coordinates></LineString>
              </Placemark>

            """
        }
        for w in waypoints {
            s += """
              <Placemark>
                <name>\(esc(w.name))</name>
                <Point><coordinates>\(coord(w.longitude)),\(coord(w.latitude)),0</coordinates></Point>
              </Placemark>

            """
        }
        s += "</Document>\n</kml>\n"
        return s
    }

    // MARK: - Helpers

    private static func coord(_ v: Double) -> String { String(format: "%.6f", v) }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
    private static func iso(_ d: Date) -> String { isoFormatter.string(from: d) }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
