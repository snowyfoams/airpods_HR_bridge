import Foundation

struct HRGlanceSharedSnapshot: Hashable {
    let isRunning: Bool
    let bpm: Int?
    let updatedAt: Date?
}

enum HRGlanceSharedState {
    static let appGroupIdentifier = "group.com.kangeshou.AirPodsHRBridge"

    private enum Key {
        static let isRunning = "hrGlance.isRunning"
        static let bpm = "hrGlance.bpm"
        static let updatedAt = "hrGlance.updatedAt"
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func save(isRunning: Bool, bpm: Int?, updatedAt: Date = Date()) {
        let defaults = defaults
        defaults.set(isRunning, forKey: Key.isRunning)

        if let bpm {
            defaults.set(bpm, forKey: Key.bpm)
        } else {
            defaults.removeObject(forKey: Key.bpm)
        }

        defaults.set(updatedAt.timeIntervalSince1970, forKey: Key.updatedAt)
        defaults.synchronize()
    }

    static func snapshot() -> HRGlanceSharedSnapshot {
        let defaults = defaults
        let rawBPM = defaults.object(forKey: Key.bpm) as? NSNumber
        let rawUpdatedAt = defaults.double(forKey: Key.updatedAt)
        let updatedAt = rawUpdatedAt > 0 ? Date(timeIntervalSince1970: rawUpdatedAt) : nil

        return HRGlanceSharedSnapshot(isRunning: defaults.bool(forKey: Key.isRunning),
                                      bpm: rawBPM?.intValue,
                                      updatedAt: updatedAt)
    }

    // MARK: - Darwin notification for cross-process signaling

    static let darwinNotificationName = "com.kangeshou.AirPodsHRBridge.glanceStateChanged" as CFString

    static func postStateChanged() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(darwinNotificationName),
            nil, nil, true)
    }
}
