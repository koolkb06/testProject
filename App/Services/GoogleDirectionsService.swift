import Foundation
import CoreLocation

/// Google Directions API 키 보관(UserDefaults). 설정에서 입력. 없으면 전철은 직선 대체.
enum GoogleConfig {
    private static let key = "google.apiKey"
    static var apiKey: String? {
        let v = UserDefaults.standard.string(forKey: key)?.trimmingCharacters(in: .whitespaces)
        return (v?.isEmpty == false) ? v : nil
    }
    static func setAPIKey(_ value: String?) {
        let trimmed = value?.trimmingCharacters(in: .whitespaces)
        if let trimmed, !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

/// 전철(대중교통) 경로를 Google Directions API로. 키가 없으면 nil(→ 직선 대체).
enum GoogleDirectionsService {
    static func transitRoute(from: RoutePlayback.Coord, to: RoutePlayback.Coord) async -> [RoutePlayback.Coord]? {
        guard let key = GoogleConfig.apiKey else { return nil }
        var comps = URLComponents(string: "https://maps.googleapis.com/maps/api/directions/json")!
        comps.queryItems = [
            .init(name: "origin", value: "\(from.latitude),\(from.longitude)"),
            .init(name: "destination", value: "\(to.latitude),\(to.longitude)"),
            .init(name: "mode", value: "transit"),
            .init(name: "key", value: key),
        ]
        guard let url = comps.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(GoogleDirectionsResponse.self, from: data)
            guard let encoded = decoded.routes.first?.overviewPolyline.points else { return nil }
            let coords = decodePolyline(encoded)
            return coords.isEmpty ? nil : coords
        } catch {
            Log.map.debug("Google 전철 경로 실패(직선 대체): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // Google encoded polyline algorithm 디코딩
    private static func decodePolyline(_ str: String) -> [RoutePlayback.Coord] {
        var coords: [RoutePlayback.Coord] = []
        var index = str.startIndex
        var lat = 0, lon = 0
        let chars = Array(str.unicodeScalars)
        var i = 0
        func nextValue() -> Int {
            var shift = 0, result = 0
            while i < chars.count {
                let b = Int(chars[i].value) - 63
                i += 1
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20 { break }
            }
            return (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
        }
        _ = index
        while i < chars.count {
            lat += nextValue()
            lon += nextValue()
            coords.append(RoutePlayback.Coord(latitude: Double(lat) / 1e5, longitude: Double(lon) / 1e5))
        }
        return coords
    }
}

private struct GoogleDirectionsResponse: Decodable {
    let routes: [Route]
    struct Route: Decodable {
        let overviewPolyline: OverviewPolyline
        enum CodingKeys: String, CodingKey { case overviewPolyline = "overview_polyline" }
    }
    struct OverviewPolyline: Decodable { let points: String }
}
