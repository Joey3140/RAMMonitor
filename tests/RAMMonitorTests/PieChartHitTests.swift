import SwiftUI
import XCTest
@testable import RAMMonitor

final class PieChartHitTests: XCTestCase {
    // Four equal quarters, clockwise from 12 o'clock.
    private let slices = ["A", "B", "C", "D"].map { MemorySlice(name: $0, value: 1, color: .gray) }
    private let plot = CGRect(x: 0, y: 0, width: 200, height: 200)   // centre (100,100), ring 55...100

    private func hit(_ x: CGFloat, _ y: CGFloat) -> String? {
        PieChartView.category(at: CGPoint(x: x, y: y), in: plot, slices: slices)
    }

    func testQuartersClockwiseFromTop() {
        XCTAssertEqual(hit(130, 20), "A")    // upper right
        XCTAssertEqual(hit(180, 130), "B")   // lower right
        XCTAssertEqual(hit(70, 180), "C")    // lower left
        XCTAssertEqual(hit(20, 70), "D")     // upper left
    }

    func testHoleAndOutsideAreMisses() {
        XCTAssertNil(hit(100, 100))   // centre
        XCTAssertNil(hit(140, 100))   // 40 from centre, inside the 55 hole
        XCTAssertNil(hit(199, 199))   // corner, beyond the 100 radius
    }

    func testEmptyChartIsAMiss() {
        let empty = ["A", "B"].map { MemorySlice(name: $0, value: 0, color: .gray) }
        XCTAssertNil(PieChartView.category(at: CGPoint(x: 130, y: 20), in: plot, slices: empty))
    }
}
