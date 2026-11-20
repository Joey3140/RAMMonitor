import XCTest
@testable import RAMMonitor

final class ProcessMemoryInfoTests: XCTestCase {
    func testFormattedMemorySwitchesToGigabytesAtOneGiB() {
        XCTAssertEqual(ProcessMemoryInfo(name: "a", memory: 512 * 1024 * 1024).formattedMemory, "512 MB")
        XCTAssertEqual(ProcessMemoryInfo(name: "a", memory: 1_073_741_823).formattedMemory, "1024 MB")
        XCTAssertEqual(ProcessMemoryInfo(name: "a", memory: 1_073_741_824).formattedMemory, "1.00 GB")
        XCTAssertEqual(ProcessMemoryInfo(name: "a", memory: 3 * 1_073_741_824 / 2).formattedMemory, "1.50 GB")
    }

    func testLabels() {
        XCTAssertEqual(ProcessMemoryInfo.label(for: "com.apple.WebKit.WebContent"), "Safari Web Content")
        XCTAssertEqual(ProcessMemoryInfo.label(for: "com.apple.WebKit.GPU"), "Safari Graphics (GPU)")
        XCTAssertEqual(ProcessMemoryInfo.label(for: "com.apple.Virtualization.VirtualMachine"), "VirtualMachine")
        XCTAssertEqual(ProcessMemoryInfo.label(for: "Google Chrome Helper (Renderer)"), "Google Chrome Helper (Renderer)")
        XCTAssertEqual(ProcessMemoryInfo.label(for: "com.example.thing"), "com.example.thing")  // only Apple's get shortened
    }

    func testMergedSumsSameNameAndRanksLargestFirst() {
        let rows = ProcessMemoryInfo.merged([("Chrome", 100), ("Finder", 150), ("Chrome", 200), ("Mail", 50)], limit: 10)
        XCTAssertEqual(rows.map(\.name), ["Chrome", "Finder", "Mail"])
        XCTAssertEqual(rows.map(\.memory), [300, 150, 50])
    }

    func testMergedKeepsTheTopN() {
        let samples = (1...15).map { (name: "p\($0)", memory: UInt64($0)) }
        XCTAssertEqual(ProcessMemoryInfo.merged(samples, limit: 3).map(\.name), ["p15", "p14", "p13"])
    }

    func testTopProcessesOnThisMachine() {
        let top = ProcessMemoryInfo.topProcesses(limit: 5)
        XCTAssertFalse(top.isEmpty)  // at least this test process is over 1 MB
        XCTAssertLessThanOrEqual(top.count, 5)
        XCTAssertEqual(top.map(\.memory), top.map(\.memory).sorted(by: >))
        XCTAssertEqual(Set(top.map(\.name)).count, top.count)
        XCTAssertTrue(top.allSatisfy { $0.memory >= 1_048_576 })
    }
}
