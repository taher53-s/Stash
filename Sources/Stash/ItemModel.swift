import Foundation
import AppKit

struct StashedItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let icon: NSImage
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }
}
