import UIKit

enum PhotoServiceError: Error {
    case encodingFailed
}

/// 저장된 사진 파일 경로. Documents 기준 상대 경로로 저장해(앱 컨테이너 경로가 바뀌어도 안전)
/// 읽을 때 `PhotoStorage.absolute`로 절대 경로로 변환한다.
struct StoredPhotoPaths: Equatable {
    let filePath: String   // 예: "photos/<uuid>.jpg"
    let thumbPath: String  // 예: "photos/<uuid>_thumb.jpg"
}

/// Documents 경로 해석 유틸.
enum PhotoStorage {
    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    /// 상대 경로 → 절대 URL
    static func absolute(_ relativePath: String) -> URL {
        documents.appendingPathComponent(relativePath)
    }
}

/// 사진 원본 + 200px 썸네일을 Documents에 저장. (설계 §4)
final class PhotoService {
    private let documents: URL
    private let subdirectory = "photos"
    private let fileManager = FileManager.default

    /// documents는 테스트에서 임시 디렉터리로 주입 가능.
    init(documents: URL = PhotoStorage.documents) {
        self.documents = documents
    }

    @discardableResult
    func store(image: UIImage, id: UUID = UUID()) throws -> StoredPhotoPaths {
        let dir = documents.appendingPathComponent(subdirectory, isDirectory: true)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

        let relOriginal = "\(subdirectory)/\(id.uuidString).jpg"
        let relThumb = "\(subdirectory)/\(id.uuidString)_thumb.jpg"

        guard let originalData = image.jpegData(compressionQuality: 0.9) else {
            throw PhotoServiceError.encodingFailed
        }
        try originalData.write(to: documents.appendingPathComponent(relOriginal))

        let thumb = ImageProcessing.thumbnail(from: image, maxDimension: 200)
        guard let thumbData = thumb.jpegData(compressionQuality: 0.8) else {
            throw PhotoServiceError.encodingFailed
        }
        try thumbData.write(to: documents.appendingPathComponent(relThumb))

        return StoredPhotoPaths(filePath: relOriginal, thumbPath: relThumb)
    }

    /// 사진 파일 삭제(원본+썸네일). 모델 삭제 시 함께 호출.
    func deleteFiles(_ paths: StoredPhotoPaths) {
        try? fileManager.removeItem(at: documents.appendingPathComponent(paths.filePath))
        try? fileManager.removeItem(at: documents.appendingPathComponent(paths.thumbPath))
    }
}
