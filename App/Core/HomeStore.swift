import Foundation

/// 집 위치 사용자 교정값을 UserDefaults에 저장. 없으면 기본 좌표(지오코딩 확정값)를 쓴다.
enum HomeStore {
    private static let latKey = "home.latitude"
    private static let lonKey = "home.longitude"
    private static let addrKey = "home.address"
    private static var defaults: UserDefaults { .standard }

    static func save(_ home: HomeLocation) {
        guard let lat = home.latitude, let lon = home.longitude else { return }
        defaults.set(lat, forKey: latKey)
        defaults.set(lon, forKey: lonKey)
        defaults.set(home.address, forKey: addrKey)
    }

    /// 저장된 교정값(좌표 포함)만 반환. 없으면 nil.
    static func load() -> HomeLocation? {
        guard defaults.object(forKey: latKey) != nil,
              defaults.object(forKey: lonKey) != nil else { return nil }
        let addr = defaults.string(forKey: addrKey) ?? HomeLocation.default.address
        return HomeLocation(
            address: addr,
            latitude: defaults.double(forKey: latKey),
            longitude: defaults.double(forKey: lonKey)
        )
    }

    static func clear() {
        defaults.removeObject(forKey: latKey)
        defaults.removeObject(forKey: lonKey)
        defaults.removeObject(forKey: addrKey)
    }
}
