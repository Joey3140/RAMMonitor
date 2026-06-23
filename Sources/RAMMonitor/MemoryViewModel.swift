import Foundation

@Observable
final class MemoryViewModel {
    var memoryInfo: MemoryInfo
    var topProcesses: [ProcessMemoryInfo] = []

    private var timer: Timer?
    private var isMenuOpen = false

    init() {
        self.memoryInfo = MemoryInfo.current()
        // topProcesses stays empty until the menu opens — the expensive per-PID
        // sweep is only ever displayed in the popover (see refreshProcesses()).
        startPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            // Cheap mach call — fine on the main thread, drives the always-visible label.
            self.memoryInfo = MemoryInfo.current()
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
            DispatchQueue.main.async { self?.topProcesses = procs }
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
