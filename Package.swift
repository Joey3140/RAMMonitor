// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RAMMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RAMMonitor",
            path: "Sources/RAMMonitor"
        )
    ]
)
