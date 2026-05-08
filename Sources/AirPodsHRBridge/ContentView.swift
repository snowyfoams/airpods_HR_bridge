import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: BridgeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(viewModel.currentBPMText)
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                    Text("BPM")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(alignment: .leading, spacing: 10) {
                    StatusRow(title: "HealthKit", value: viewModel.healthStatus)
                    StatusRow(title: "BLE", value: viewModel.bleStatus)
                    StatusRow(title: "Workout", value: viewModel.workoutStatus)
                    StatusRow(title: "HR Glance", value: viewModel.glanceStatus)
                    StatusRow(title: "Subscribers", value: "\(viewModel.subscriberCount)")
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button(action: {
                    Task { await viewModel.toggleBridge() }
                }) {
                    Text(viewModel.isRunning ? "Stop BLE Bridge" : "Start BLE Bridge")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    Task { await viewModel.toggleGlance() }
                }) {
                    Text(viewModel.isGlanceRunning ? "Stop HR Glance" : "Start HR Glance")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                Button(action: {
                    Task { await viewModel.toggleDemo() }
                }) {
                    Text(viewModel.isDemoRunning ? "Stop Demo Mode" : "Start Demo Mode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                Text("BLE Bridge broadcasts heart rate for compatible bike computers. HR Glance starts a discarded workout and shows live BPM on the Lock Screen and Dynamic Island. Demo Mode simulates BPM for App Store review, screenshots, and app previews.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("HR Bridge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Privacy") {
                        PrivacyView()
                    }
                }
            }
        }
    }
}

private struct StatusRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

private struct PrivacyView: View {
    var body: some View {
        List {
            Section("Health Data") {
                Text("The app reads heart-rate data from HealthKit only after you start HR Glance or BLE Bridge. Workout sessions are used to access live workout heart-rate metrics and are discarded when stopped.")
            }

            Section("Bluetooth") {
                Text("BLE Bridge broadcasts BPM locally as a Bluetooth LE Heart Rate Service only while you keep the bridge running. Demo Mode broadcasts simulated BPM for testing.")
            }

            Section("No Server Upload") {
                Text("The app has no account, no analytics SDK, no tracking SDK, and does not upload heart-rate data to a server.")
            }

            Section("Reminders") {
                Text("HR Glance can send local high-heart-rate reminders. Notifications are generated on device and are not medical alerts.")
            }

            Section("Medical Disclaimer") {
                Text("This app is for fitness display and sensor interoperability. It is not a medical device and does not diagnose, treat, or provide medical advice.")
            }
        }
        .navigationTitle("Privacy")
    }
}
