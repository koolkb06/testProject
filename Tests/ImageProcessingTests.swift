import XCTest
import UIKit
@testable import TravelTracker

final class ImageProcessingTests: XCTestCase {
    func image(_ size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func testDownscaleKeepsAspectRatioWithinMax() {
        let thumb = ImageProcessing.thumbnail(from: image(CGSize(width: 400, height: 300)), maxDimension: 200)
        XCTAssertEqual(thumb.size.width, 200, accuracy: 0.5)
        XCTAssertEqual(thumb.size.height, 150, accuracy: 0.5)
    }

    func testDoesNotUpscaleSmallImage() {
        let thumb = ImageProcessing.thumbnail(from: image(CGSize(width: 100, height: 50)), maxDimension: 200)
        XCTAssertEqual(thumb.size.width, 100, accuracy: 0.5)
        XCTAssertEqual(thumb.size.height, 50, accuracy: 0.5)
    }

    func testTallImageLimitsHeight() {
        let thumb = ImageProcessing.thumbnail(from: image(CGSize(width: 100, height: 400)), maxDimension: 200)
        XCTAssertEqual(thumb.size.height, 200, accuracy: 0.5)
        XCTAssertEqual(thumb.size.width, 50, accuracy: 0.5)
    }
}
