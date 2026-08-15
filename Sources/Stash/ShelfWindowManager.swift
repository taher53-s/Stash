import AppKit
import SwiftUI

@MainActor
class ShelfWindowManager {
    var panel: NSPanel?
    var isVisible = false
    
    init() {
        setupPanel()
    }
    
    func setupPanel() {
        let contentView = ShelfView(manager: self)
        
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 260),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        guard let panel = panel else { return }
        
        panel.level = .floating // Stays above other windows
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        
        panel.contentView = NSHostingView(rootView: contentView)
    }
    
    func show(at point: NSPoint? = nil) {
        guard let panel = panel else { return }
        
        if let point = point {
            // Position the window near the mouse, smoothly centered relative to cursor
            var newOrigin = NSPoint(x: point.x + 15, y: point.y - 130)
            
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
    }
    
    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }
}
