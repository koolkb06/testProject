import Foundation

/// 여행의 시작점(집). 사용자 요청: 여행은 집(탄천상로 6)에서 시작한다.
///
/// 주소는 확정되어 있으나 정확한 좌표는 임의로 지정하지 않는다.
/// 실기기에서 `CLGeocoder`로 주소를 좌표로 변환하거나 사용자가 확인한 뒤
/// `latitude`/`longitude`를 채운다. 좌표가 nil이면 시작점은 주소로만 기록된다.
struct HomeLocation: Equatable {
    var address: String
    var latitude: Double?
    var longitude: Double?

    var hasCoordinate: Bool { latitude != nil && longitude != nil }

    static let `default` = HomeLocation(
        address: "탄천상로 6",
        latitude: nil,
        longitude: nil
    )
}
