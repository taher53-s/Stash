import Foundation
import AppKit
import QuickLookThumbnailing

class StashedItem: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let name: String
    @Published var thumbnail: NSImage
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        // Initial fallback to standard file icon
        self.thumbnail = NSWorkspace.shared.icon(forFile: url.path)
        
        // Generate real thumbnail representation asynchronously
        generateThumbnail()
    }
    
    private func generateThumbnail() {
        let size = CGSize(width: 128, height: 128)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] (thumbnailRepresentation, error) in
            if let image = thumbnailRepresentation?.nsImage {
                DispatchQueue.main.async {
                    self?.thumbnail = image
                }
            }
        }
    }
}
