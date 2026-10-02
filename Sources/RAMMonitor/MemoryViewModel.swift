import Foundation
import AppKit

@Observable
final class MemoryViewModel {
    var memoryInfo: MemoryInfo
    var topProcesses: [ProcessMemoryInfo] = []

    private var timer: Timer?
    private var isMenuOpen = false

    init() {
        // Zeroed (0% used) fallback if the very first mach call fails — corrects
        // itself on the next tick; polling keeps the last good reading thereafter.
        self.memoryInfo = MemoryInfo.current() ?? MemoryInfo(
            appMemory: 0, wired: 0, compressed: 0, cached: 0,
            free: 0, total: ProcessInfo.processInfo.physicalMemory
        )
        // topProcesses stays empty until the menu opens — the expensive per-PID
        // sweep is only ever displayed in the popover (see refreshProcesses()).
        startPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            // Cheap mach call — fine on the main thread, drives the always-visible label.
            if let info = MemoryInfo.current() { self.memoryInfo = info }
            // Self-heal: onAppear/onDisappear for MenuBarExtra(.window) have a
            // history of missed calls across macOS versions. Reconcile with the
            // actual window state so a missed onDisappear can't leave the sweep
            // running forever, and a missed onAppear can't freeze the list.
            // (The only non-status-bar window this app owns is the menu panel.)
            let panelVisible = NSApp.windows.contains {
                $0.isVisible && !String(describing: type(of: $0)).contains("StatusBar")
            }
            if panelVisible != self.isMenuOpen { self.isMenuOpen = panelVisible }
            // The heavy ~2N-syscall process sweep only matters while the popover
            // is open; skip it entirely when closed.
            if self.isMenuOpen { self.refreshProcesses() }
        }
    }

    /// Run the expensive per-PID enumeration off the main thread, then hop back
    /// to assign the @Observable property.
    private func refreshProcesses() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let procs = ProcessMemoryInfo.topProcesses()
            DispatchQueue.main.async {
                guard let self, self.isMenuOpen else { return }  // menu closed mid-sweep — drop the stale result
                self.topProcesses = procs
            }
        }
    }

    func menuOpened() {
        isMenuOpen = true
        refreshProcesses()
    }

    func menuClosed() {
        isMenuOpen = false
    }

    deinit {
        timer?.invalidate()
    }
}
