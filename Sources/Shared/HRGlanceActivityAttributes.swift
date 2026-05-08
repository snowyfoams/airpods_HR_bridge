import ActivityKit
import Foundation

struct HRGlanceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var bpm: Int?
        var status: String
        var startedAt: Date
        var updatedAt: Date

        var bpmText: String {
            bpm.map(String.init) ?? "--"
        }

        var assessment: HRGlanceHeartRateAssessment {
            HRGlanceHeartRateAssessment.evaluate(bpm: bpm)
        }
    }

    var title: String
}
