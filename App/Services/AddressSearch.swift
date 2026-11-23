import Foundation
import MapKit
import Combine

/// 주소/장소 자동완성(MKLocalSearchCompleter). 한국·일본 등 Apple 지도 데이터 기반. (사용자 요청)
final class AddressSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query: String = "" {
        didSet { completer.queryFragment = query }
    }
    @Published private(set) var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    /// 검색 결과를 특정 지역 주변으로 편향.
    func setRegion(center: CLLocationCoordinate2D, spanDegrees: Double = 4) {
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
        )
    }

    func clear() {
        query = ""
        results = []
    }

    /// 자동완성 항목을 실제 좌표로 해석.
    func resolve(_ completion: MKLocalSearchCompletion,
                 handler: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            handler(response?.mapItems.first?.placemark.coordinate)
        }
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
