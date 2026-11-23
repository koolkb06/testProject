import UIKit

/// 이미지 축소 등 순수 처리. (설계 §4: 200px 썸네일 생성)
enum ImageProcessing {
    /// 비율을 유지하며 가장 긴 변이 maxDimension이 되도록 축소. 확대는 하지 않는다.
    static func thumbnail(from image: UIImage, maxDimension: CGFloat = 200) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > 0 else { return image }
        let scale = min(maxDimension / longest, 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // 픽셀 크기를 points와 동일하게(디스크 용량 예측 가능)
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
