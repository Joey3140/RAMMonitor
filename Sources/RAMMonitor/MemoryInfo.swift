import SwiftUI
import Darwin

struct MemoryInfo {
    let appMemory: UInt64
    let wired: UInt64
    let compressed: UInt64
    let cached: UInt64
    let free: UInt64
    let total: UInt64

    var used: UInt64 { appMemory + wired + compressed }
    var usedFraction: Double { Double(used) / Double(total) }
    var usedPercentage: Int { Int((usedFraction * 100).rounded()) }

    var thresholdColor: Color {
        switch usedFraction {
        case ..<0.6: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }

    func gigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / (1024 * 1024 * 1024)
    }

    static func current() -> MemoryInfo {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        )

        // Balance the send right that mach_host_self() adds to the host port —
        // otherwise its user-reference count climbs once per call (every 3s) forever.
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(host, HOST_VM_INFO64, intPtr, &count)
            }
        }

        let total = ProcessInfo.processInfo.physicalMemory

        guard result == KERN_SUCCESS else {
            return MemoryInfo(
                appMemory: 0, wired: 0, compressed: 0,
                cached: 0, free: total, total: total
            )
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let internalPages = UInt64(stats.internal_page_count) * pageSize
        let purgeable = UInt64(stats.purgeable_count) * pageSize
        let externalPages = UInt64(stats.external_page_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        let appMemory = internalPages > purgeable ? internalPages - purgeable : 0
        let cached = purgeable + externalPages
        let used = appMemory + wired + compressed
        let free = total > (used + cached) ? total - used - cached : 0

        return MemoryInfo(
            appMemory: appMemory,
            wired: wired,
            compressed: compressed,
            cached: cached,
            free: free,
            total: total
        )
    }
}
