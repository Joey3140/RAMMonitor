# RAMMonitor

A native macOS menu-bar memory monitor written in Swift.

RAMMonitor lives in your menu bar, showing the current memory usage percentage next to a chip icon. Clicking it opens a popover with a full breakdown of how macOS is using your RAM — including a donut chart, per-category legend, and the top memory-consuming processes.

## Features

- Menu-bar indicator showing live used-memory percentage with a `memorychip` icon
- Color-coded usage (green under 60%, yellow 60–80%, red above 80%)
- Donut chart breaking RAM down into five categories: App Memory, Wired, Compressed, Cached Files, Free
- Tap any donut slice to drill into that category — App Memory and Compressed show the top apps holding it; Wired filters to system processes; Cached Files explains the purgeable cache
- Legend rows with per-category byte totals, percentage of total RAM, and an info button that expands a plain-language explanation
- Top Processes list (up to 10) with resident-set memory, sorted descending; processes sharing a name (e.g. Chrome helpers) are merged
- Filters out `com.apple.*` helper processes and anything using less than 1 MB
- Total physical RAM displayed in the header
- Polls every 3 seconds

## Screenshot

<!-- TODO: add screenshot -->

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9+ toolchain (Xcode 15 or the command-line tools)

## Install / Build

```bash
./bundle.sh
open RAMMonitor.app
```

`bundle.sh` runs `swift build -c release`, copies the binary into a `RAMMonitor.app` bundle alongside `Resources/Info.plist`, and prints the launch command.

To run without bundling:

```bash
swift run -c release
```

## How it works

Memory stats come from the Mach kernel via `host_statistics64(mach_host_self(), HOST_VM_INFO64, …)`, which returns a `vm_statistics64` struct. RAMMonitor reads `internal_page_count`, `purgeable_count`, `external_page_count`, `wire_count`, and `compressor_page_count`, then multiplies each by `vm_kernel_page_size` to convert to bytes. Total physical RAM comes from `ProcessInfo.processInfo.physicalMemory`.

Per-process memory uses the libproc API: `proc_listallpids` to enumerate every PID, then `proc_pidinfo(pid, PROC_PIDTASKINFO, …)` to read each task's resident size, and `proc_name` to resolve the process name.

The UI is SwiftUI's `MenuBarExtra` scene with `Charts` (`SectorMark`) for the donut. State is an `@Observable` view model on a 3-second `Timer`.

## License

PolyForm Noncommercial 1.0.0 — see [LICENSE](LICENSE). Free for personal use, hobby projects, and noncommercial organizations. Commercial use is not permitted.
