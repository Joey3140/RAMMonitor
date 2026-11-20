import XCTest
@testable import RAMMonitor

final class MemoryInfoTests: XCTestCase {
    private let gib: UInt64 = 1024 * 1024 * 1024

    private func info(app: UInt64 = 0, wired: UInt64 = 0, compressed: UInt64 = 0,
                      cached: UInt64 = 0, free: UInt64 = 0, total: UInt64) -> MemoryInfo {
        MemoryInfo(appMemory: app, wired: wired, compressed: compressed, cached: cached, free: free, total: total)
    }

    func testUsedIsAppPlusWiredPlusCompressed() {
        let m = info(app: 4 * gib, wired: 2 * gib, compressed: 1 * gib, cached: 3 * gib, free: 6 * gib, total: 16 * gib)
        XCTAssertEqual(m.used, 7 * gib)
        XCTAssertEqual(m.usedFraction, 7.0 / 16.0, accuracy: 1e-12)
        XCTAssertEqual(m.usedPercentage, 44)  // 43.75 rounds to 44
        XCTAssertEqual(m.gigabytes(m.total), 16, accuracy: 1e-12)
    }

    func testThresholdColourBands() {
        XCTAssertEqual(info(app: 59, total: 100).thresholdColor, .green)
        XCTAssertEqual(info(app: 60, total: 100).thresholdColor, .yellow)
        XCTAssertEqual(info(app: 79, total: 100).thresholdColor, .yellow)
        XCTAssertEqual(info(app: 80, total: 100).thresholdColor, .red)
        XCTAssertEqual(info(app: 100, total: 100).thresholdColor, .red)
    }

    func testFromCountersSplitsLikeActivityMonitor() {
        let m = MemoryInfo.from(internalBytes: 6 * gib, purgeableBytes: 1 * gib, externalBytes: 2 * gib,
                                wiredBytes: 2 * gib, compressedBytes: 1 * gib, total: 16 * gib)
        XCTAssertEqual(m.appMemory, 5 * gib)   // internal minus purgeable
        XCTAssertEqual(m.cached, 3 * gib)      // purgeable plus file-backed
        XCTAssertEqual(m.free, 5 * gib)        // what's left of the total
        XCTAssertEqual(m.used + m.cached + m.free, m.total)
    }

    func testFromCountersNeverUnderflows() {
        // Purgeable can briefly exceed internal, and the counters can exceed the
        // physical total; UInt64 subtraction would trap.
        let m = MemoryInfo.from(internalBytes: 1 * gib, purgeableBytes: 2 * gib, externalBytes: 20 * gib,
                                wiredBytes: 1 * gib, compressedBytes: 0, total: 16 * gib)
        XCTAssertEqual(m.appMemory, 0)
        XCTAssertEqual(m.free, 0)
    }

    func testCurrentReadsThisMachine() throws {
        let m = try XCTUnwrap(MemoryInfo.current())
        XCTAssertEqual(m.total, Foundation.ProcessInfo.processInfo.physicalMemory)
        XCTAssertGreaterThan(m.wired, 0)
        XCTAssertLessThanOrEqual(m.used, m.total)
    }

    func testLegendPercentsAlwaysTotal100() {
        // Thirds: independent rounding shows 33+33+33 = 99.
        let thirds = info(app: 1, wired: 1, compressed: 1, total: 3)
        XCTAssertEqual(thirds.legendPercents.reduce(0, +), 100)
        XCTAssertEqual(thirds.legendPercents.sorted(), [0, 0, 33, 33, 34])

        // Largest remainder gets the extra point: 12.6 / 37.4 / 50 -> 13 / 37 / 50.
        let m = info(app: 126, wired: 374, compressed: 500, total: 1000)
        XCTAssertEqual(m.legendPercents, [13, 37, 50, 0, 0])

        for seed in 1...200 {
            var g = SplitMix(seed: UInt64(seed))
            let r = info(app: g.next() % gib, wired: g.next() % gib, compressed: g.next() % gib,
                         cached: g.next() % gib, free: g.next() % gib, total: 16 * gib)
            XCTAssertEqual(r.legendPercents.reduce(0, +), 100, "seed \(seed)")
        }
    }

    func testLegendPercentsAllZeroWhenEmpty() {
        XCTAssertEqual(info(total: 0).legendPercents, [0, 0, 0, 0, 0])
    }
}

/// Deterministic random numbers, so a failure reproduces.
struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
