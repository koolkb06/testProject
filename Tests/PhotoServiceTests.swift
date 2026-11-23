import XCTest
import UIKit
@testable import TravelTracker

final class PhotoServiceTests: XCTestCase {
    var tmp: URL!

    override func setUpWithError() throws {
        tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("phototest-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tmp)
    }

    func image() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300)).image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
        }
    }

    func testStoreWritesOriginalAndThumbnail() throws {
        let service = PhotoService(documents: tmp)
        let id = UUID()
        let paths = try service.store(image: image(), id: id)

        XCTAssertEqual(paths.filePath, "photos/\(id.uuidString).jpg")
        XCTAssertEqual(paths.thumbPath, "photos/\(id.uuidString)_thumb.jpg")

        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: tmp.appendingPathComponent(paths.filePath).path))
        XCTAssertTrue(fm.fileExists(atPath: tmp.appendingPathComponent(paths.thumbPath).path))
    }

    func testThumbnailIsSmallerThanOriginalOnDisk() throws {
        let service = PhotoService(documents: tmp)
        let paths = try service.store(image: image())
        let fm = FileManager.default
        let origSize = try fm.attributesOfItem(atPath: tmp.appendingPathComponent(paths.filePath).path)[.size] as! Int
        let thumbSize = try fm.attributesOfItem(atPath: tmp.appendingPathComponent(paths.thumbPath).path)[.size] as! Int
        XCTAssertLessThan(thumbSize, origSize)
    }

    func testDeleteRemovesFiles() throws {
        let service = PhotoService(documents: tmp)
        let paths = try service.store(image: image())
        service.deleteFiles(paths)
        let fm = FileManager.default
        XCTAssertFalse(fm.fileExists(atPath: tmp.appendingPathComponent(paths.filePath).path))
        XCTAssertFalse(fm.fileExists(atPath: tmp.appendingPathComponent(paths.thumbPath).path))
    }
}
