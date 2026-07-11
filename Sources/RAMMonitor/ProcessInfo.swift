import Foundation
import Darwin

struct ProcessMemoryInfo: Identifiable {
    let id: pid_t
    let name: String
    let memory: UInt64  // bytes (phys_footprint — same metric as Activity Monitor's Memory column)

    var memoryMB: Double { Double(memory) / (1024 * 1024) }
    var memoryGB: Double { Double(memory) / (1024 * 1024 * 1024) }

    var formattedMemory: String {
        if memory >= 1_073_741_824 {
            return String(format: "%.2f GB", memoryGB)
        } else {
            return String(format: "%.0f MB", memoryMB)
        }
    }

    /// Friendly labels for well-known reverse-DNS process names.
    private static let friendlyNames: [String: String] = [
        "com.apple.WebKit.WebContent": "Safari Web Content",
        "com.apple.WebKit.Networking": "Safari Networking",
        "com.apple.WebKit.GPU": "Safari Graphics (GPU)",
    ]

    /// proc_name truncates at 31 bytes, so prefer the executable path's basename;
    /// this is also the merge key, so truncation would merge unrelated binaries.
    private static func displayName(for pid: pid_t) -> String {
        var pathBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        var name = ""
        if proc_pidpath(pid, &pathBuffer, UInt32(MAXPATHLEN)) > 0 {
            name = (String(cString: pathBuffer) as NSString).lastPathComponent
        }
        if name.isEmpty {
            var nameBuffer = [CChar](repeating: 0, count: 256)
            proc_name(pid, &nameBuffer, 256)
            name = String(cString: nameBuffer)
        }
        if let friendly = friendlyNames[name] { return friendly }
        // Generic reverse-DNS names read badly in a menu — show the last component.
        if name.hasPrefix("com.apple."), let tail = name.split(separator: ".").last {
            return String(tail)
        }
        return name
    }

    static func topProcesses(limit: Int = 10) -> [ProcessMemoryInfo] {
        let pidCount = proc_listallpids(nil, 0)
        guard pidCount > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: Int(pidCount) * 2)
        let bufferSize = Int32(MemoryLayout<pid_t>.stride * pids.count)
        let actualCount = proc_listallpids(&pids, bufferSize)
        guard actualCount > 0 else { return [] }

        var processes: [ProcessMemoryInfo] = []
        var indexByName: [String: Int] = [:]   // O(1) name->index for the merge below

        for i in 0..<Int(actualCount) {
            let pid = pids[i]
            if pid == 0 { continue }

            // phys_footprint is Apple's per-process attribution metric (footprint(1));
            // unlike resident size it excludes shared pages, so merged rows can be
            // summed without double-counting and match Activity Monitor.
            var usage = rusage_info_current()
            let ret = withUnsafeMutablePointer(to: &usage) { ptr in
                ptr.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { infoPtr in
                    proc_pid_rusage(pid, RUSAGE_INFO_CURRENT, infoPtr)
                }
            }
            guard ret == 0 else { continue }

            let memory = usage.ri_phys_footprint
            if memory < 1_048_576 { continue }  // skip < 1MB

            let name = displayName(for: pid)
            if name.isEmpty { continue }

            // Merge processes with same name (e.g., multiple Chrome helpers)
            if let idx = indexByName[name] {
                let existing = processes[idx]
                processes[idx] = ProcessMemoryInfo(
                    id: existing.id,
                    name: name,
                    memory: existing.memory + memory
                )
            } else {
                indexByName[name] = processes.count
                processes.append(ProcessMemoryInfo(id: pid, name: name, memory: memory))
            }
        }

        processes.sort { $0.memory > $1.memory }
        return Array(processes.prefix(limit))
    }
}
