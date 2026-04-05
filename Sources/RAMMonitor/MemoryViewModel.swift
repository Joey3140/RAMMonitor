import Foundation

@Observable
final class MemoryViewModel {
    var memoryInfo: MemoryInfo
    var topProcesses: [ProcessMemoryInfo] = []

    private var timer: Timer?

    init() {
        self.memoryInfo = MemoryInfo.current()
        self.topProcesses = ProcessMemoryInfo.topProcesses()
        startPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.memoryInfo = MemoryInfo.current()
            self?.topProcesses = ProcessMemoryInfo.topProcesses()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
