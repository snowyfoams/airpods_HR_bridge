import AppIntents
import WidgetKit

struct ToggleHRGlanceIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Toggle HR Glance"
    static let description = IntentDescription("Start or stop AirPods heart-rate glance without opening the app UI.")
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    func perform() async throws -> some IntentResult {
#if APP_EXTENSION
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
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

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
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    func perform() async throws -> some IntentResult {
#if APP_EXTENSION
        return .result()
#else
        await BridgeViewModel.shared.stopGlanceFromIntent()
        WidgetCenter.shared.reloadTimelines(ofKind: HRGlanceWidgetKind.launcher)
        return .result()
#endif
    }
}
