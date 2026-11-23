import Foundation
import SwiftData

/// 사용자 프로필(지도 현재 위치 마커의 원형 사진 등). 2단계+에서 사용. 현재는 스키마 등록 목적.
@Model
final class Profile {
    var imagePath: String?
    var displayName: String

    init(imagePath: String? = nil, displayName: String) {
        self.imagePath = imagePath
        self.displayName = displayName
    }
}
