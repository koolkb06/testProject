import Foundation

/// 여행의 시작점(집). 사용자 요청: 여행은 집(탄천상로 6)에서 시작한다.
///
/// 좌표는 Apple CLGeocoder로 "경기도 성남시 탄천상로 6"을 변환한 결과(2026-11-23 확정).
/// 지오코더는 행정구역을 용인시(경기도)로 반환하며, 탄천상로가 성남/용인 경계를 지나기 때문이다.
/// 실제 위치가 다르면 추후 설정의 지도 핀으로 교체(후속 작업).
struct HomeLocation: Equatable {
    var address: String
    var latitude: Double?
    var longitude: Double?

    var hasCoordinate: Bool { latitude != nil && longitude != nil }

    static let `default` = HomeLocation(
        address: "탄천상로 6",
        latitude: 37.332388,
        longitude: 127.112209
    )
}
