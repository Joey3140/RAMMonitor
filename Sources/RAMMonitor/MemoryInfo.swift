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

    /// nil when the mach call fails — callers keep their last good reading
    /// instead of displaying a bogus all-free snapshot.
    static func current() -> MemoryInfo? {
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

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        return from(
            internalBytes: UInt64(stats.internal_page_count) * pageSize,
            purgeableBytes: UInt64(stats.purgeable_count) * pageSize,
            externalBytes: UInt64(stats.external_page_count) * pageSize,
            wiredBytes: UInt64(stats.wire_count) * pageSize,
            compressedBytes: UInt64(stats.compressor_page_count) * pageSize,
            total: total
        )
    }

    /// The Activity Monitor-style split of the VM counters (in bytes), apart from
    /// the mach call so it can be tested.
    static func from(internalBytes internalPages: UInt64, purgeableBytes purgeable: UInt64,
                     externalBytes externalPages: UInt64, wiredBytes wired: UInt64,
                     compressedBytes compressed: UInt64, total: UInt64) -> MemoryInfo {
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

    /// Integer percentages for the five legend rows, in display order.
    /// Largest-remainder rounding over the category sum so they total exactly 100
    /// (independent rounding could show 99 or 101).
    var legendPercents: [Int] {
        let values = [appMemory, wired, compressed, cached, free]
        let total = Double(values.reduce(0, +))
        guard total > 0 else { return Array(repeating: 0, count: values.count) }
        let exact = values.map { Double($0) / total * 100 }
        var percents = exact.map { Int($0.rounded(.down)) }
        var leftover = 100 - percents.reduce(0, +)
        for i in exact.indices.sorted(by: {
            exact[$0] - exact[$0].rounded(.down) > exact[$1] - exact[$1].rounded(.down)
        }) {
            guard leftover > 0 else { break }
            percents[i] += 1
            leftover -= 1
        }
        return percents
    }
}
