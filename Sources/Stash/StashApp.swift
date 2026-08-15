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
    var shelfManagers: [ShelfWindowManager] = []

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
        menu.addItem(NSMenuItem(title: "New Shelf", action: #selector(createNewShelf), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Stash", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Request accessibility permissions silently on launch if needed
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        print("Accessibility Enabled: \(accessEnabled)")
        
        self.dragDetector = DragDetector()
        self.dragDetector?.onShakeDetected = { [weak self] location in
            self?.handleShake(at: location)
        }
        self.dragDetector?.startMonitoring()
    }
    
    func handleShake(at location: NSPoint) {
        // Find an empty shelf that is not visible, or just the first empty one
        if let emptyShelf = shelfManagers.first(where: { $0.isEmpty }) {
            emptyShelf.show(at: location)
        } else {
            // Spawn a new shelf window
            spawnShelf(at: location)
        }
    }
    
    @objc func createNewShelf() {
        let mouseLocation = NSEvent.mouseLocation
        spawnShelf(at: mouseLocation)
    }
    
    func spawnShelf(at location: NSPoint? = nil) {
        let manager = ShelfWindowManager(onClose: { [weak self] id in
            self?.shelfManagers.removeAll(where: { $0.id == id })
        })
        shelfManagers.append(manager)
        manager.show(at: location)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
