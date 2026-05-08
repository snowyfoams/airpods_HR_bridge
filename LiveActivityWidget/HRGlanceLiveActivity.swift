import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct HRGlanceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HRGlanceActivityAttributes.self) { context in
            HRGlanceLockScreenView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HR")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.bpmText)
                            .font(.title2.bold())
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("BPM")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.status)
                        Spacer()
                        Button(intent: StopHRGlanceIntent()) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .tint(.red)
                        Text(context.state.updatedAt, style: .time)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(context.state.assessment.isWarning ? .orange : .red)
            } compactTrailing: {
                Text(context.state.bpmText)
                    .font(.caption2.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(context.state.assessment.isWarning ? .orange : .red)
            }
            .keylineTint(context.state.assessment.isWarning ? .orange : .red)
        }
    }
}

private struct HRGlanceLockScreenView: View {
    let state: HRGlanceActivityAttributes.ContentState

    private var tint: Color {
        state.assessment.isWarning ? .orange : .red
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: state.assessment.symbolName)
                .font(.title2)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("HR Glance")
                    .font(.headline)
                Text(state.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(intent: StopHRGlanceIntent()) {
                Image(systemName: "stop.fill")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .tint(tint)

            VStack(alignment: .trailing, spacing: 0) {
                Text(state.bpmText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("BPM")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
