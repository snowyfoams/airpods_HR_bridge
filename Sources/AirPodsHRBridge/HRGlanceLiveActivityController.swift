import ActivityKit
import Foundation

@MainActor
final class HRGlanceLiveActivityController {
    private var activity: Activity<HRGlanceActivityAttributes>?

    init() {
        activity = Activity<HRGlanceActivityAttributes>.activities.first
    }

    var hasActiveActivity: Bool {
        activity != nil || !Activity<HRGlanceActivityAttributes>.activities.isEmpty
    }

    func start(initialBPM: Int?, startedAt: Date = Date()) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw BridgeError.liveActivitiesUnavailable
        }

        let attributes = HRGlanceActivityAttributes(title: "HR Glance")
        let state = HRGlanceActivityAttributes.ContentState(bpm: initialBPM,
                                                            status: HRGlanceHeartRateAssessment.evaluate(bpm: initialBPM).title,
                                                            startedAt: startedAt,
                                                            updatedAt: Date())
        let content = ActivityContent(state: state,
                                      staleDate: Date().addingTimeInterval(15))
        activity = try Activity.request(attributes: attributes,
                                        content: content,
                                        pushType: nil)
    }

    func update(bpm: Int?) async {
        guard let activity else { return }
        let state = HRGlanceActivityAttributes.ContentState(bpm: bpm,
                                                            status: HRGlanceHeartRateAssessment.evaluate(bpm: bpm).title,
                                                            startedAt: activity.content.state.startedAt,
                                                            updatedAt: Date())
        await activity.update(ActivityContent(state: state,
                                              staleDate: Date().addingTimeInterval(15)))
    }

    func end(finalBPM: Int?) async {
        let state = HRGlanceActivityAttributes.ContentState(bpm: finalBPM,
                                                            status: "Stopped",
                                                            startedAt: activity?.content.state.startedAt ?? Date(),
                                                            updatedAt: Date())
        let content = ActivityContent(state: state,
                                      staleDate: Date().addingTimeInterval(5))

        for activeActivity in Activity<HRGlanceActivityAttributes>.activities {
            await activeActivity.end(content, dismissalPolicy: .immediate)
        }

        activity = nil
    }
}
