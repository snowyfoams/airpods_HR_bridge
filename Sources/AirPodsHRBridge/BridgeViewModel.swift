import Foundation
import Combine
import HealthKit
import WidgetKit

@MainActor
final class BridgeViewModel: ObservableObject {
    static let shared = BridgeViewModel()

    @Published var isRunning = false
    @Published var isGlanceRunning = false
    @Published var isDemoRunning = false
    @Published var currentBPM: Int?
    @Published var healthStatus = "Not authorized"
    @Published var bleStatus = "Idle"
    @Published var workoutStatus = "Stopped"
    @Published var glanceStatus = "Idle"
    @Published var subscriberCount = 0

    private let workoutManager = WorkoutHeartRateManager()
    private let blePeripheral = BLEHeartRatePeripheral(localName: "AirPodsHRBridge")
    private let liveActivityController = HRGlanceLiveActivityController()
    private let reminderManager = HeartRateReminderManager()
    private var cancellables = Set<AnyCancellable>()
    private var lastWidgetReload = Date.distantPast
    private var lastWidgetAssessmentTitle: String?
    private var demoTask: Task<Void, Never>?
    private var isBridgeBLEStarted = false

    var currentBPMText: String {
        currentBPM.map(String.init) ?? "--"
    }

    private init() {
        workoutManager.$latestBPM
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bpm in
                guard let self else { return }
                self.currentBPM = bpm
                if let bpm, self.isRunning {
                    self.publishBridgeBPM(bpm)
                }
                if self.isGlanceRunning {
                    self.updateGlanceSurfaces(bpm: bpm)
                }
            }
            .store(in: &cancellables)

        workoutManager.$status
            .receive(on: DispatchQueue.main)
            .assign(to: &$workoutStatus)

        workoutManager.$authorizationStatusText
            .receive(on: DispatchQueue.main)
            .assign(to: &$healthStatus)

        blePeripheral.$status
            .receive(on: DispatchQueue.main)
            .assign(to: &$bleStatus)

        blePeripheral.$subscriberCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$subscriberCount)
    }

    func toggleBridge() async {
        if isRunning {
            await stopBridge()
        } else {
            await startBridge()
        }
    }

    func startBridge() async {
        do {
            if isDemoRunning {
                await stopDemo()
            }
            if isGlanceRunning {
                await stopGlance()
            }
            currentBPM = nil
            isBridgeBLEStarted = false
            blePeripheral.prepareForFirstMeasurement()
            try await workoutManager.requestAuthorization()
            try await workoutManager.startWorkout(activityType: .cycling, locationType: .outdoor)
            isRunning = true
            if let currentBPM {
                publishBridgeBPM(currentBPM)
            }
        } catch {
            healthStatus = "Error"
            workoutStatus = error.localizedDescription
            blePeripheral.stop()
            isBridgeBLEStarted = false
            isRunning = false
        }
    }

    func stopBridge() async {
        await workoutManager.stopWorkout()
        blePeripheral.stop()
        isBridgeBLEStarted = false
        isRunning = false
    }

    func toggleGlance() async {
        if isGlanceRunning {
            await stopGlance()
        } else {
            await startGlance()
        }
    }

    func handleOpenURL(_ url: URL) async {
        guard HRGlanceDeepLink.isStartGlance(url) else { return }
        if !isGlanceRunning {
            await startGlance()
        }
    }

    func startGlanceFromIntent() async {
        if !isGlanceRunning {
            await startGlance()
        }
    }

    func stopGlanceFromIntent() async {
        if isGlanceRunning {
            await stopGlance()
        } else {
            await liveActivityController.end(finalBPM: currentBPM)
            HRGlanceSharedState.save(isRunning: false, bpm: nil)
            lastWidgetAssessmentTitle = nil
            glanceStatus = "Stopped"
            WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        }
    }

    func toggleGlanceFromIntent() async {
        if isDemoRunning {
            await stopDemo()
            return
        }
        if isGlanceRunning || liveActivityController.hasActiveActivity {
            await stopGlanceFromIntent()
        } else {
            await startGlanceFromIntent()
        }
    }

    func startGlance() async {
        do {
            if isDemoRunning {
                await stopDemo()
            }
            if isRunning {
                await stopBridge()
            }
            try await workoutManager.requestAuthorization()
            try await workoutManager.startWorkout(activityType: .other, locationType: .unknown)
            try liveActivityController.start(initialBPM: currentBPM)
            HRGlanceSharedState.save(isRunning: true, bpm: currentBPM)
            lastWidgetAssessmentTitle = HRGlanceHeartRateAssessment.evaluate(bpm: currentBPM).title
            glanceStatus = "Live Activity running"
            isGlanceRunning = true
            WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        } catch {
            healthStatus = "Error"
            glanceStatus = error.localizedDescription
            await liveActivityController.end(finalBPM: currentBPM)
            await workoutManager.stopWorkout()
            HRGlanceSharedState.save(isRunning: false, bpm: nil)
            lastWidgetAssessmentTitle = nil
            isGlanceRunning = false
            WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        }
    }

    func stopGlance() async {
        await liveActivityController.end(finalBPM: currentBPM)
        await workoutManager.stopWorkout()
        HRGlanceSharedState.save(isRunning: false, bpm: nil)
        lastWidgetAssessmentTitle = nil
        reminderManager.reset()
        glanceStatus = "Stopped"
        isGlanceRunning = false
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
    }

    func toggleDemo() async {
        if isDemoRunning {
            await stopDemo()
        } else {
            await startDemo()
        }
    }

    func startDemo() async {
        if isRunning {
            await stopBridge()
        }
        if isGlanceRunning {
            await stopGlance()
        }
        if isDemoRunning {
            await stopDemo()
        }

        let initialBPM = 72
        do {
            try liveActivityController.start(initialBPM: initialBPM)
            glanceStatus = "Demo running"
        } catch {
            glanceStatus = "Demo running: \(error.localizedDescription)"
        }

        isDemoRunning = true
        workoutStatus = "Demo"
        blePeripheral.updateHeartRate(initialBPM)
        blePeripheral.start()
        updateGlanceSurfaces(bpm: initialBPM, forceWidgetReload: true)
        startDemoPulse()
    }

    func stopDemo() async {
        demoTask?.cancel()
        demoTask = nil
        await liveActivityController.end(finalBPM: currentBPM)
        blePeripheral.stop()
        HRGlanceSharedState.save(isRunning: false, bpm: nil)
        lastWidgetAssessmentTitle = nil
        currentBPM = nil
        reminderManager.reset()
        isDemoRunning = false
        workoutStatus = "Stopped"
        glanceStatus = "Demo stopped"
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
    }

    private func reloadLauncherWidgetIfNeeded(force: Bool = false) {
        let now = Date()
        guard force || now.timeIntervalSince(lastWidgetReload) >= 5 else { return }
        lastWidgetReload = now
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
    }

    private func updateGlanceSurfaces(bpm: Int?, forceWidgetReload: Bool = false) {
        currentBPM = bpm
        if let bpm, isDemoRunning {
            blePeripheral.updateHeartRate(bpm)
        }
        if let bpm, isGlanceRunning {
            reminderManager.handle(bpm: bpm)
        }
        HRGlanceSharedState.save(isRunning: true, bpm: bpm)
        let assessmentTitle = HRGlanceHeartRateAssessment.evaluate(bpm: bpm).title
        let shouldReloadImmediately = forceWidgetReload || assessmentTitle != lastWidgetAssessmentTitle
        lastWidgetAssessmentTitle = assessmentTitle
        Task { await liveActivityController.update(bpm: bpm) }
        reloadLauncherWidgetIfNeeded(force: shouldReloadImmediately)
    }

    private func publishBridgeBPM(_ bpm: Int) {
        if !isBridgeBLEStarted {
            blePeripheral.updateHeartRate(bpm)
            blePeripheral.start()
            isBridgeBLEStarted = true
            return
        }

        blePeripheral.updateHeartRate(bpm)
    }

    private func startDemoPulse() {
        let demoValues = [72, 76, 84, 96, 106, 118, 126, 112, 92, 78]
        demoTask = Task { @MainActor [weak self] in
            var index = 0
            while !Task.isCancelled {
                guard let self, self.isDemoRunning else { return }
                self.updateGlanceSurfaces(bpm: demoValues[index % demoValues.count])
                index += 1
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
}
