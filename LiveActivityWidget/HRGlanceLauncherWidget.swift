import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct HRGlanceLauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: HRGlanceWidgetKind.launcher,
                            provider: HRGlanceLauncherProvider()) { entry in
            HRGlanceLauncherView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("HR Glance")
        .description("Start or stop AirPods heart-rate glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct HRGlanceLauncherEntry: TimelineEntry {
    let date: Date
    let bpm: Int?
    let isRunning: Bool

    var assessment: HRGlanceHeartRateAssessment {
        guard isRunning else {
            return HRGlanceHeartRateAssessment(title: "Check HR",
                                               detail: "Tap once to start",
                                               symbolName: "heart.text.square.fill",
                                               isWarning: false)
        }

        return HRGlanceHeartRateAssessment(title: bpm == nil ? "Starting" : "Monitoring",
                                           detail: bpm == nil ? "Waiting for AirPods" : "Live Activity has BPM",
                                           symbolName: "heart.fill",
                                           isWarning: false)
    }

    var actionTitle: String {
        isRunning ? "Stop" : "Start"
    }

    var actionSymbolName: String {
        isRunning ? "stop.fill" : "play.fill"
    }
}

private struct HRGlanceLauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> HRGlanceLauncherEntry {
        HRGlanceLauncherEntry(date: Date(), bpm: 72, isRunning: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (HRGlanceLauncherEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HRGlanceLauncherEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> HRGlanceLauncherEntry {
        let snapshot = HRGlanceSharedState.snapshot()
        if snapshot.isRunning || snapshot.bpm != nil {
            return HRGlanceLauncherEntry(date: Date(),
                                         bpm: snapshot.bpm,
                                         isRunning: snapshot.isRunning)
        }

        let activity = Activity<HRGlanceActivityAttributes>.activities.first
        return HRGlanceLauncherEntry(date: Date(),
                                     bpm: activity?.content.state.bpm,
                                     isRunning: activity != nil)
    }
}

private struct HRGlanceLauncherView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HRGlanceLauncherEntry

    private var tint: Color {
        entry.isRunning ? .red : .secondary
    }

    var body: some View {
        Button(intent: ToggleHRGlanceIntent()) {
            switch family {
            case .accessoryCircular:
                circularContent
            case .accessoryRectangular:
                rectangularContent
            case .accessoryInline:
                inlineContent
            default:
                smallContent
            }
        }
        .buttonStyle(.plain)
    }

    private var circularContent: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: entry.isRunning ? entry.assessment.symbolName : entry.actionSymbolName)
                    .font(.caption2)
                    .foregroundStyle(tint)
                Text(entry.isRunning ? "Live" : entry.actionTitle)
                    .font(.caption.bold())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }

    private var rectangularContent: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.assessment.symbolName)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.assessment.title)
                    .font(.headline)
                Text(entry.assessment.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: entry.actionSymbolName)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private var inlineContent: some View {
        Label(entry.isRunning ? "HR Monitoring" : "Start HR", systemImage: entry.assessment.symbolName)
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: entry.assessment.symbolName)
                    .font(.title2)
                    .foregroundStyle(tint)
                Spacer()
                Text(entry.actionTitle)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.assessment.title)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(entry.assessment.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Capsule()
                .fill(tint.opacity(entry.isRunning ? 0.95 : 0.7))
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}
