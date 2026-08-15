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
    private var shelfCounter = 1

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status item directly via AppKit for guaranteed menu bar presence
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenu()
        
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
    
    func updateMenu() {
        if let button = statusItem?.button {
            let activeCount = shelfManagers.filter({ !$0.isEmpty }).count
            if activeCount > 0 {
                button.title = "📦 Stash (\(activeCount))"
                button.image = nil
            } else {
                if let image = NSImage(systemSymbolName: "archivebox.fill", accessibilityDescription: "Stash") {
                    button.image = image
                    button.title = ""
                } else {
                    button.title = "📦 Stash"
                }
            }
        }
        
        let menu = NSMenu()
        
        // List active non-empty shelves
        let nonEmpthShelves = shelfManagers.filter { !$0.isEmpty }
        if !nonEmpthShelves.isEmpty {
            let headerItem = NSMenuItem(title: "Active Shelves", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            menu.addItem(headerItem)
            
            for manager in shelfManagers {
                let statusText = manager.isVisible ? "Visible" : "Hidden"
                let title = "  \(manager.title) (\(manager.itemCount) items) [\(statusText)]"
                let menuItem = NSMenuItem(title: title, action: #selector(shelfMenuItemClicked(_:)), keyEquivalent: "")
                menuItem.representedObject = manager.id
                menu.addItem(menuItem)
            }
            
            menu.addItem(NSMenuItem.separator())
        }
        
        menu.addItem(NSMenuItem(title: "New Shelf", action: #selector(createNewShelf), keyEquivalent: "n"))
        if !shelfManagers.isEmpty {
            menu.addItem(NSMenuItem(title: "Close All Shelves", action: #selector(closeAllShelves), keyEquivalent: "w"))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Stash", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func shelfMenuItemClicked(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? UUID,
           let manager = shelfManagers.first(where: { $0.id == id }) {
            if manager.isVisible {
                manager.hide()
            } else {
                let mouseLocation = NSEvent.mouseLocation
                manager.show(at: mouseLocation)
            }
        }
    }
    
    func handleShake(at location: NSPoint) {
        // First check if there is a hidden shelf with items in it -> unhide it!
        if let hiddenShelf = shelfManagers.first(where: { !$0.isVisible && !$0.isEmpty }) {
            hiddenShelf.show(at: location)
        }
        // Next check if there is an empty visible/hidden shelf -> move & show it
        else if let emptyShelf = shelfManagers.first(where: { $0.isEmpty }) {
            emptyShelf.show(at: location)
        }
        // Otherwise spawn a brand new shelf!
        else {
            spawnShelf(at: location)
        }
    }
    
    @objc func createNewShelf() {
        let mouseLocation = NSEvent.mouseLocation
        spawnShelf(at: mouseLocation)
    }
    
    func spawnShelf(at location: NSPoint? = nil) {
        let title = "Stash \(shelfCounter)"
        shelfCounter += 1
        
        let manager = ShelfWindowManager(
            title: title,
            onClose: { [weak self] id in
                self?.shelfManagers.removeAll(where: { $0.id == id })
                self?.updateMenu()
            },
            onStateChange: { [weak self] in
                self?.updateMenu()
            }
        )
        shelfManagers.append(manager)
        manager.show(at: location)
        updateMenu()
    }
    
    @objc func closeAllShelves() {
        for manager in shelfManagers {
            manager.close()
        }
        shelfManagers.removeAll()
        updateMenu()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
