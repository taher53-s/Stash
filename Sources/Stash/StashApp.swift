import SwiftUI
import AppKit

@main
struct StashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var dragDetector: DragDetector?
    var shelfManager: ShelfWindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status item directly via AppKit for guaranteed menu bar presence
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "archivebox.fill", accessibilityDescription: "Stash") {
                button.image = image
            } else {
                button.title = "📦 Stash"
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Shelf", action: #selector(toggleShelf), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Stash", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Request accessibility permissions silently on launch if needed
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        print("Accessibility Enabled: \(accessEnabled)")
        
        self.shelfManager = ShelfWindowManager()
        self.dragDetector = DragDetector(shelfManager: self.shelfManager!)
        self.dragDetector?.startMonitoring()
    }
    
    @objc func toggleShelf() {
        if shelfManager?.isVisible == true {
            shelfManager?.hide()
        } else {
            let mouseLocation = NSEvent.mouseLocation
            shelfManager?.show(at: mouseLocation)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
