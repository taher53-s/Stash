import AppKit
import SwiftUI

class StashPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
class ShelfWindowManager: ObservableObject {
    let id = UUID()
    @Published var title: String
    var panel: StashPanel?
    var isVisible = false
    var isEmpty = true
    var itemCount: Int = 0
    var onClose: ((UUID) -> Void)?
    var onStateChange: (() -> Void)?
    
    init(title: String, onClose: @escaping (UUID) -> Void, onStateChange: @escaping () -> Void) {
        self.title = title
        self.onClose = onClose
        self.onStateChange = onStateChange
        setupPanel()
    }
    
    func setupPanel() {
        let contentView = ShelfView(manager: self)
        
        panel = StashPanel(
            contentRect: NSRect(x: 0, y: 0, width: 304, height: 326),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        guard let panel = panel else { return }
        
        panel.level = (UserDefaults.standard.object(forKey: "stash.keepShelvesOnTop") as? Bool ?? true) ? .floating : .normal
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        
        panel.contentView = NSHostingView(rootView: contentView)
    }
    
    func updateTitle(_ newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            self.title = trimmed
            onStateChange?()
        }
    }
    
    func makeKey() {
        panel?.makeKey()
    }
    
    func show(at point: NSPoint? = nil) {
        guard let panel = panel else { return }
        
        if let point = point {
            // Position the window near the mouse, smoothly centered relative to cursor
            var newOrigin = NSPoint(x: point.x + 16, y: point.y - 163)
            
            // Screen bounds safety check
            if let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) {
                if newOrigin.x + panel.frame.width > screen.frame.maxX - 10 {
                    newOrigin.x = screen.frame.maxX - panel.frame.width - 10
                }
                if newOrigin.y < screen.frame.minY + 10 {
                    newOrigin.y = screen.frame.minY + 10
                }
                if newOrigin.y + panel.frame.height > screen.frame.maxY - 10 {
                    newOrigin.y = screen.frame.maxY - panel.frame.height - 10
                }
            }
            panel.setFrameOrigin(newOrigin)
        }
        
        panel.orderFront(nil)
        isVisible = true
        onStateChange?()
    }
    
    func hide() {
        panel?.orderOut(nil)
        isVisible = false
        onStateChange?()
    }
    
    func close() {
        panel?.orderOut(nil)
        isVisible = false
        onClose?(id)
        onStateChange?()
    }
    
    func updateItemCount(_ count: Int) {
        self.itemCount = count
        self.isEmpty = (count == 0)
        onStateChange?()
    }
}
