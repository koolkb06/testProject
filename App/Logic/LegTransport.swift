import Foundation

/// 계획 구간의 이동 수단. (사용자 요청)
enum LegTransport: String, CaseIterable, Identifiable {
    case car, flight, transit, walk

    var id: String { rawValue }

    var label: String {
        switch self {
        case .car: return "자동차"
        case .flight: return "비행기"
        case .transit: return "전철"
        case .walk: return "도보"
        }
    }

    var systemImage: String {
        switch self {
        case .car: return "car.fill"
        case .flight: return "airplane"
        case .transit: return "tram.fill"
        case .walk: return "figure.walk"
        }
    }

    static func from(_ raw: String?) -> LegTransport {
        LegTransport(rawValue: raw ?? "") ?? .car
    }
}
