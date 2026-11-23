import SwiftUI
import UIKit

/// UIActivityViewController 래퍼. 파일(GPX/KML) 공유용.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Identifiable URL 래퍼 (sheet(item:)용).
struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}
