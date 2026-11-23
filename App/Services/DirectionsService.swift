import Foundation
import MapKit

extension MKPolyline {
    /// 폴리라인의 좌표 배열 추출.
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

/// 이동 수단별 경로 좌표열 계산. (사용자 요청: 자동차/비행기/전철/도보)
/// - 자동차·도보: Apple MKDirections 실제 도로 경로
/// - 비행기: 대권(great-circle) 곡선 (어떤 지도 API도 비행경로 없음)
/// - 전철: Google Directions(키 있으면), 없으면 nil → 직선 대체
enum DirectionsService {
    /// 경로 좌표열. nil이면 호출측이 직선으로 대체.
    static func route(
        from: RoutePlayback.Coord,
        to: RoutePlayback.Coord,
        transport: LegTransport
    ) async -> [RoutePlayback.Coord]? {
        switch transport {
        case .car:
            return await apple(from: from, to: to, type: .automobile)
        case .walk:
            return await apple(from: from, to: to, type: .walking)
        case .flight:
            return Geo.geodesic(lat1: from.latitude, lon1: from.longitude,
                                lat2: to.latitude, lon2: to.longitude)
                .map { RoutePlayback.Coord(latitude: $0.latitude, longitude: $0.longitude) }
        case .transit:
            return await GoogleDirectionsService.transitRoute(from: from, to: to)
        }
    }

    private static func apple(
        from: RoutePlayback.Coord, to: RoutePlayback.Coord,
        type: MKDirectionsTransportType
    ) async -> [RoutePlayback.Coord]? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: from.latitude, longitude: from.longitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: to.latitude, longitude: to.longitude)))
        request.transportType = type
        do {
            let response = try await MKDirections(request: request).calculate()
            guard let polyline = response.routes.first?.polyline else { return nil }
            return polyline.coordinates.map {
                RoutePlayback.Coord(latitude: $0.latitude, longitude: $0.longitude)
            }
        } catch {
            Log.map.debug("길찾기 실패(직선 대체): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
