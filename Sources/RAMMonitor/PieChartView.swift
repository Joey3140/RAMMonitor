import SwiftUI
import Charts

struct MemorySlice: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color
}

struct PieChartView: View {
    let memoryInfo: MemoryInfo
    @Binding var selectedCategory: String?

    private var slices: [MemorySlice] {
        [
            MemorySlice(name: "App Memory", value: memoryInfo.gigabytes(memoryInfo.appMemory), color: .blue),
            MemorySlice(name: "Wired", value: memoryInfo.gigabytes(memoryInfo.wired), color: .red),
            MemorySlice(name: "Compressed", value: memoryInfo.gigabytes(memoryInfo.compressed), color: .orange),
            MemorySlice(name: "Cached Files", value: memoryInfo.gigabytes(memoryInfo.cached), color: .yellow),
            MemorySlice(name: "Free", value: memoryInfo.gigabytes(memoryInfo.free), color: .green),
        ]
    }

    private func findCategory(at location: CGPoint, in size: CGSize) -> String? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y

        let distance = sqrt(dx * dx + dy * dy)
        let outerRadius = min(size.width, size.height) / 2
        let innerRadius = outerRadius * 0.55
        guard distance >= innerRadius && distance <= outerRadius else { return nil }

        // Angle from top, clockwise (matching Swift Charts SectorMark default)
        var angle = atan2(dx, -dy) // angle from 12 o'clock, clockwise
        if angle < 0 { angle += 2 * .pi }
        let fraction = angle / (2 * .pi)

        let total = slices.reduce(0.0) { $0 + $1.value }
        var cumulative = 0.0
        for slice in slices {
            cumulative += slice.value / total
            if fraction <= cumulative {
                return slice.name
            }
        }
        return slices.last?.name
    }

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Size", slice.value),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(slice.color)
            .cornerRadius(3)
            .opacity(selectedCategory == nil || selectedCategory == slice.name ? 1.0 : 0.4)
        }
        .chartLegend(.hidden)
        .frame(width: 180, height: 180)
        .contentShape(Circle())
        .onTapGesture { location in
            let tapped = findCategory(at: location, in: CGSize(width: 180, height: 180))
            selectedCategory = selectedCategory == tapped ? nil : tapped
        }
    }
}
