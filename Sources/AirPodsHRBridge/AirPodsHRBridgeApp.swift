import SwiftUI

@main
struct AirPodsHRBridgeApp: App {
    @StateObject private var viewModel = BridgeViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    Task { await viewModel.handleOpenURL(url) }
                }
        }
    }
}
