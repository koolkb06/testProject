import Foundation
import CoreLocation

/// "내 위치" 버튼을 눌렀을 때 할 일.
enum MyLocationAction: Equatable {
    /// 현재 위치로 이동하고 계속 따라간다.
    case follow
    /// 아직 권한을 묻지 않았으므로 권한을 요청한다.
    case requestPermission
    /// 거부/제한됨 → 설정 앱에서 직접 허용하도록 안내한다.
    case openSettings
}

/// "내 위치" 버튼의 판단 로직. 뷰와 분리해 GPS 없이 테스트한다.
enum MyLocation {
    /// 현재 위치를 보여줄 때의 확대 정도(위도·경도 폭, 약 1km).
    static let zoomDelta = 0.01

    static func action(for status: CLAuthorizationStatus) -> MyLocationAction {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .follow
        case .notDetermined:
            return .requestPermission
        case .denied, .restricted:
            return .openSettings
        @unknown default:
            return .openSettings
        }
    }

    /// GPS 위치를 아직 받지 못했을 때 대신 보여줄 영역.
    /// 마지막 기록 위치 → 집 순서로 쓰고, 둘 다 없으면 nil.
    static func fallbackRegion(lastSample: LocationSample?, home: HomeLocation) -> RegionBox? {
        if let sample = lastSample {
            return region(latitude: sample.latitude, longitude: sample.longitude)
        }
        if let latitude = home.latitude, let longitude = home.longitude {
            return region(latitude: latitude, longitude: longitude)
        }
        return nil
    }

    private static func region(latitude: Double, longitude: Double) -> RegionBox {
        RegionBox(
            centerLatitude: latitude,
            centerLongitude: longitude,
            latitudeDelta: zoomDelta,
            longitudeDelta: zoomDelta
        )
    }
}
