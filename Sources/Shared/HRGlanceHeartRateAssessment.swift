struct HRGlanceHeartRateAssessment: Hashable {
    let title: String
    let detail: String
    let symbolName: String
    let isWarning: Bool

    static func evaluate(bpm: Int?) -> HRGlanceHeartRateAssessment {
        guard let bpm else {
            return HRGlanceHeartRateAssessment(title: "Checking",
                                               detail: "Waiting for AirPods",
                                               symbolName: "heart",
                                               isWarning: false)
        }

        switch bpm {
        case ..<50:
            return HRGlanceHeartRateAssessment(title: "Low HR",
                                               detail: "Below usual range",
                                               symbolName: "arrow.down.heart.fill",
                                               isWarning: true)
        case 50..<100:
            return HRGlanceHeartRateAssessment(title: "Normal",
                                               detail: "In normal range",
                                               symbolName: "heart.fill",
                                               isWarning: false)
        case 100..<120:
            return HRGlanceHeartRateAssessment(title: "Elevated",
                                               detail: "Above resting range",
                                               symbolName: "waveform.path.ecg",
                                               isWarning: false)
        default:
            return HRGlanceHeartRateAssessment(title: "High HR",
                                               detail: "Check intensity",
                                               symbolName: "exclamationmark.heart.fill",
                                               isWarning: true)
        }
    }
}
