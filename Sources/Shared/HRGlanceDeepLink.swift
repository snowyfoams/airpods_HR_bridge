import Foundation

enum HRGlanceDeepLink {
    static let scheme = "airpodshrbridge"
    static let startGlanceHost = "start-glance"
    static let startGlanceURL = URL(string: "\(scheme)://\(startGlanceHost)")!

    static func isStartGlance(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == startGlanceHost
    }
}
