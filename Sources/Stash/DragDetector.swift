import AppKit

@MainActor
class DragDetector {
    var globalMonitor: Any?
    var localMonitor: Any?
    let shelfManager: ShelfWindowManager
    
    // Shake detection state
    private var lastMousePositions: [NSPoint] = []
    private var lastEventTime: TimeInterval = 0
    private let shakeThreshold: CGFloat = 300.0 // Distance threshold for a single "shake" stroke
    private let directionChangesRequired = 2
    private let maxTimeBetweenShakes: TimeInterval = 0.6
    
    init(shelfManager: ShelfWindowManager) {
        self.shelfManager = shelfManager
    }
    
    func startMonitoring() {
        // Track global left mouse drags
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            self?.handleMouseDragged(event: event)
        }
        
        // Also track left mouse up to reset state or hide shelf if needed
        localMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.resetShakeDetection()
        }
    }
    
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleMouseDragged(event: NSEvent) {
        // Only trigger if shelf is not already visible
        guard !shelfManager.isVisible else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let currentTime = Date().timeIntervalSince1970
        
        // Reset if it's been too long since the last event
        if currentTime - lastEventTime > maxTimeBetweenShakes {
            lastMousePositions.removeAll()
        }
        
        lastEventTime = currentTime
        lastMousePositions.append(mouseLocation)
        
        // Keep only the last N positions to avoid unbounded growth
        if lastMousePositions.count > 30 {
            lastMousePositions.removeFirst()
        }
        
        if detectShake(positions: lastMousePositions) {
            print("Shake detected!")
            shelfManager.show(at: mouseLocation)
            resetShakeDetection()
        }
    }
    
    private func resetShakeDetection() {
        lastMousePositions.removeAll()
    }
    
    private func detectShake(positions: [NSPoint]) -> Bool {
        guard positions.count > 5 else { return false }
        
        var directionChanges = 0
        var currentDirectionX: CGFloat = 0
        var distanceInCurrentDirection: CGFloat = 0
        
        for i in 1..<positions.count {
            let prev = positions[i-1]
            let curr = positions[i]
            
            let dx = curr.x - prev.x
            
            if dx == 0 { continue }
            
            let newDirectionX = dx > 0 ? 1.0 : -1.0
            
            if currentDirectionX == 0 {
                currentDirectionX = newDirectionX
                distanceInCurrentDirection += abs(dx)
            } else if newDirectionX == currentDirectionX {
                distanceInCurrentDirection += abs(dx)
            } else {
                // Direction changed!
                if distanceInCurrentDirection > 15 { // Minimal distance to count as a real stroke
                    directionChanges += 1
                }
                currentDirectionX = newDirectionX
                distanceInCurrentDirection = abs(dx)
            }
        }
        
        return directionChanges >= directionChangesRequired
    }
}
