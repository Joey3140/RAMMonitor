import SwiftUI

@main
struct RAMMonitorApp: App {
    @State private var viewModel = MemoryViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(memoryInfo: viewModel.memoryInfo, topProcesses: viewModel.topProcesses)
                .onAppear { viewModel.menuOpened() }
                .onDisappear { viewModel.menuClosed() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                Text("\(viewModel.memoryInfo.usedPercentage)%")
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
