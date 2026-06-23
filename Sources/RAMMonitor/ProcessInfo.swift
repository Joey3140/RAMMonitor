import Foundation
import Darwin

struct ProcessMemoryInfo: Identifiable {
    let id: pid_t
    let name: String
    let memory: UInt64  // bytes (resident size)

    var memoryMB: Double { Double(memory) / (1024 * 1024) }
    var memoryGB: Double { Double(memory) / (1024 * 1024 * 1024) }

    var formattedMemory: String {
        if memory >= 1_073_741_824 {
            return String(format: "%.2f GB", memoryGB)
        } else {
            return String(format: "%.0f MB", memoryMB)
        }
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
        let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.stride)

        for i in 0..<Int(actualCount) {
            let pid = pids[i]
            if pid == 0 { continue }

            var taskInfo = proc_taskinfo()
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)
            guard ret == taskInfoSize else { continue }

            var nameBuffer = [CChar](repeating: 0, count: 256)
            proc_name(pid, &nameBuffer, 256)
            let name = String(cString: nameBuffer)
            if name.isEmpty { continue }

            // Clean up helper process names
            if name.hasPrefix("com.apple.") { continue }

            let memory = taskInfo.pti_resident_size
            if memory < 1_048_576 { continue }  // skip < 1MB

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
