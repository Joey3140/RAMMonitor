// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RAMMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RAMMonitor",
            path: "Sources/RAMMonitor"
        ),
        // `tests/` (lowercase) because the harness already made that folder and
        // the Mac's file system ignores case.
        .testTarget(
            name: "RAMMonitorTests",
            dependencies: ["RAMMonitor"],
            path: "tests/RAMMonitorTests"
        ),
    ]
)
