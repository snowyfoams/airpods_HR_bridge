import SwiftUI

@main
struct AirPodsHRBridgeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = BridgeViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    Task { await viewModel.handleOpenURL(url) }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await viewModel.syncWithWidgetState() }
            }
        }
    }
}
