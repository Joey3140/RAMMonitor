import SwiftUI

struct MenuBarView: View {
    let memoryInfo: MemoryInfo
    let topProcesses: [ProcessMemoryInfo]
    @State private var expandedTooltip: String?
    @State private var selectedCategory: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Header
                HStack {
                    Text("RAM Monitor")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.1f GB Total", memoryInfo.gigabytes(memoryInfo.total)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Large usage display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(memoryInfo.usedPercentage)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(memoryInfo.thresholdColor)
                    Text("%")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(memoryInfo.thresholdColor)
                    Text("Used")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    Spacer()
                }

                // Usage bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(memoryInfo.thresholdColor)
                            .frame(width: geo.size.width * memoryInfo.usedFraction)
                    }
                }
                .frame(height: 8)

                // Donut chart
                PieChartView(memoryInfo: memoryInfo, selectedCategory: $selectedCategory)
                    .padding(.vertical, 4)

                // Category detail when a pie section is selected
                if let category = selectedCategory {
                    categoryDetail(for: category)
                }

                // Legend
                VStack(spacing: 6) {
                    let percents = legendPercents
                    legendRow("App Memory", bytes: memoryInfo.appMemory, percent: percents[0], color: .blue,
                              tooltip: "RAM currently in use by apps and processes — excludes purgeable caches")
                    legendRow("Wired", bytes: memoryInfo.wired, percent: percents[1], color: .red,
                              tooltip: "RAM reserved by the system (macOS kernel, drivers) — cannot be freed or compressed")
                    legendRow("Compressed", bytes: memoryInfo.compressed, percent: percents[2], color: .orange,
                              tooltip: "Inactive data squeezed in RAM to make room, without writing to disk — fast to decompress when needed")
                    legendRow("Cached Files", bytes: memoryInfo.cached, percent: percents[3], color: .yellow,
                              tooltip: "File-backed and purgeable data kept in RAM as cache — can be reclaimed instantly if an app needs more memory")
                    legendRow("Free", bytes: memoryInfo.free, percent: percents[4], color: .green,
                              tooltip: "Completely unused RAM available immediately")
                }

                // Top processes
                if !topProcesses.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Top Processes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(topProcesses) { process in
                            HStack(spacing: 8) {
                                Text(process.name)
                                    .font(.callout)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Text(process.formattedMemory)
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Quit button
                Button("Quit RAMMonitor") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            .padding(16)
        }
        .frame(width: 300, height: 620)
    }

    private var categoryColor: Color {
        switch selectedCategory {
        case "App Memory": return .blue
        case "Wired": return .red
        case "Compressed": return .orange
        case "Cached Files": return .yellow
        case "Free": return .green
        default: return .secondary
        }
    }

    @ViewBuilder
    private func categoryDetail(for category: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 8, height: 8)
                Text(category)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    selectedCategory = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            switch category {
            case "App Memory":
                Text("Apps actively using this RAM:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(topProcesses.prefix(8)) { process in
                    processRow(process)
                }

            case "Wired":
                Text("Wired memory is held by the macOS kernel, drivers, and low-level system services — it can't be attributed to the apps listed here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

            case "Compressed":
                Text("Inactive data macOS has squeezed in RAM to make room — it expands automatically when its app needs it. Per-app compressed amounts aren't visible to a monitoring app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

            case "Cached Files":
                Text("File-backed and purgeable data cached in RAM — macOS reclaims this instantly when apps need more memory. It isn't attributable to individual apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

            case "Free":
                Text("No apps are using this memory — it's completely available for new tasks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

            default:
                EmptyView()
            }
        }
        .padding(10)
        .background(categoryColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func processRow(_ process: ProcessMemoryInfo) -> some View {
        HStack(spacing: 6) {
            Text(process.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Text(process.formattedMemory)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    /// Integer percentages for the five legend rows, in display order.
    /// Largest-remainder rounding over the category sum so they total exactly 100
    /// (independent rounding could show 99 or 101).
    private var legendPercents: [Int] {
        let values = [memoryInfo.appMemory, memoryInfo.wired, memoryInfo.compressed,
                      memoryInfo.cached, memoryInfo.free]
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

    private func legendRow(_ name: String, bytes: UInt64, percent: Int, color: Color, tooltip: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.callout)
                Button {
                    expandedTooltip = expandedTooltip == name ? nil : name
                } label: {
                    Image(systemName: expandedTooltip == name ? "info.circle.fill" : "info.circle")
                        .font(.caption)
                        .foregroundStyle(expandedTooltip == name ? color : .secondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(String(format: "%.2f GB", memoryInfo.gigabytes(bytes)))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(String(format: "(%d%%)", percent))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .frame(width: 40, alignment: .trailing)
            }

            if expandedTooltip == name {
                Text(tooltip)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
