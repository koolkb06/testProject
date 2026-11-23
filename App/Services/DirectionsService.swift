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

/// 두 지점 사이 실제 도로 경로를 MKDirections로 계산. (사용자 요청: 직선 대신 길 따라가기)
enum DirectionsService {
    static func route(
        from: RoutePlayback.Coord,
        to: RoutePlayback.Coord,
        transport: MKDirectionsTransportType = .automobile
    ) async -> [RoutePlayback.Coord]? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: from.latitude, longitude: from.longitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: to.latitude, longitude: to.longitude)))
        request.transportType = transport

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
