import ActivityKit
import AppIntents
import WidgetKit

struct ToggleHRGlanceIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Toggle HR Glance"
    static let description = IntentDescription("Start or stop AirPods heart-rate glance without opening the app UI.")

    func perform() async throws -> some IntentResult {
#if APP_EXTENSION
        let snapshot = HRGlanceSharedState.snapshot()
        let hasActivity = !Activity<HRGlanceActivityAttributes>.activities.isEmpty
        let isCurrentlyRunning = snapshot.isRunning || hasActivity

        if isCurrentlyRunning {
            for activity in Activity<HRGlanceActivityAttributes>.activities {
                let state = HRGlanceActivityAttributes.ContentState(
                    bpm: snapshot.bpm,
                    status: "Stopped",
                    startedAt: activity.content.state.startedAt,
                    updatedAt: Date())
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .immediate)
            }
            HRGlanceSharedState.save(isRunning: false, bpm: nil)
        } else {
            HRGlanceSharedState.save(isRunning: true, bpm: nil)
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                let attributes = HRGlanceActivityAttributes(title: "HR Glance")
                let state = HRGlanceActivityAttributes.ContentState(
                    bpm: nil,
                    status: "Starting…",
                    startedAt: Date(),
                    updatedAt: Date())
                try? Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state,
                                            staleDate: Date().addingTimeInterval(15)),
                    pushType: nil)
            }
        }
        HRGlanceSharedState.postStateChanged()
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        return .result()
#else
        await BridgeViewModel.shared.toggleGlanceFromIntent()
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        return .result()
#endif
    }
}

struct StartHRGlanceIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start HR Glance"
    static let description = IntentDescription("Start AirPods heart-rate glance without opening the app UI.")

    func perform() async throws -> some IntentResult {
#if APP_EXTENSION
        return .result()
#else
        await BridgeViewModel.shared.startGlanceFromIntent()
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        return .result()
#endif
    }
}

struct StopHRGlanceIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop HR Glance"
    static let description = IntentDescription("Stop AirPods heart-rate glance without opening the app UI.")

    func perform() async throws -> some IntentResult {
#if APP_EXTENSION
        for activity in Activity<HRGlanceActivityAttributes>.activities {
            let state = HRGlanceActivityAttributes.ContentState(
                bpm: activity.content.state.bpm,
                status: "Stopped",
                startedAt: activity.content.state.startedAt,
                updatedAt: Date())
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate)
        }
        HRGlanceSharedState.save(isRunning: false, bpm: nil)
        HRGlanceSharedState.postStateChanged()
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        return .result()
#else
        await BridgeViewModel.shared.stopGlanceFromIntent()
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        return .result()
#endif
    }
}
