import Foundation
import HealthKit

@MainActor
final class WorkoutHeartRateManager: NSObject, ObservableObject {
    @Published var latestBPM: Int?
    @Published var status: String = "Stopped"
    @Published var authorizationStatusText: String = "Not requested"

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var workoutStartDate: Date?

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let workoutType = HKObjectType.workoutType()
    private let maximumHeartRateSampleAge: TimeInterval = 8

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw BridgeError.healthKitUnavailable
        }

        // AirPods Pro 3 HR flows through HealthKit during Fitness / supported workout apps.
        // Apple guidance for third-party workout apps requires permission to read HR and read/record workouts.
        let readTypes: Set<HKObjectType> = [heartRateType, workoutType]
        let shareTypes: Set<HKSampleType> = [workoutType]

        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)

        switch healthStore.authorizationStatus(for: workoutType) {
        case .sharingAuthorized:
            authorizationStatusText = "Authorized"
        case .sharingDenied:
            authorizationStatusText = "Denied"
            throw BridgeError.healthKitAuthorizationDenied
        case .notDetermined:
            authorizationStatusText = "Not determined"
            throw BridgeError.healthKitAuthorizationDenied
        @unknown default:
            authorizationStatusText = "Unknown"
        }
    }

    func startWorkout(activityType: HKWorkoutActivityType,
                      locationType: HKWorkoutSessionLocationType) async throws {
        latestBPM = nil

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = locationType

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        self.session = session
        self.builder = builder
        session.delegate = self
        builder.delegate = self

        status = "Preparing"
        session.prepare()

        let startDate = Date()
        workoutStartDate = startDate
        session.startActivity(with: startDate)
        try await builder.beginCollection(at: startDate)
        status = "Running"
    }

    func stopWorkout() async {
        guard let session, let builder else { return }
        status = "Stopping"
        let endDate = Date()
        session.stopActivity(with: endDate)

        do {
            try await builder.endCollection(at: endDate)
            builder.discardWorkout()
        } catch {
            builder.discardWorkout()
            status = "Discard error: \(error.localizedDescription)"
        }

        session.end()
        self.session = nil
        self.builder = nil
        self.workoutStartDate = nil
        status = "Stopped"
    }

    private func updateForStatistics(_ statistics: HKStatistics?) {
        guard let quantity = statistics?.mostRecentQuantity() else { return }

        if let sampleInterval = statistics?.mostRecentQuantityDateInterval() {
            if let workoutStartDate, sampleInterval.end < workoutStartDate {
                return
            }

            guard Date().timeIntervalSince(sampleInterval.end) <= maximumHeartRateSampleAge else {
                return
            }
        }

        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let bpm = Int(quantity.doubleValue(for: bpmUnit).rounded())
        guard bpm > 0, bpm < 255 else { return }
        latestBPM = bpm
    }
}

extension WorkoutHeartRateManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        Task { @MainActor in
            switch toState {
            case .notStarted: status = "Not started"
            case .prepared: status = "Prepared"
            case .running: status = "Running"
            case .paused: status = "Paused"
            case .stopped: status = "Stopped"
            case .ended: status = "Ended"
            @unknown default: status = "Unknown"
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didFailWithError error: Error) {
        Task { @MainActor in
            status = "Workout error: \(error.localizedDescription)"
        }
    }
}

extension WorkoutHeartRateManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for sampleType in collectedTypes {
            guard let quantityType = sampleType as? HKQuantityType,
                  quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) else { continue }

            let statistics = workoutBuilder.statistics(for: quantityType)
            Task { @MainActor in
                self.updateForStatistics(statistics)
            }
        }
    }
}

enum BridgeError: LocalizedError {
    case healthKitUnavailable
    case healthKitAuthorizationDenied
    case liveActivitiesUnavailable

    var errorDescription: String? {
        switch self {
        case .healthKitUnavailable:
            return "HealthKit is not available on this device."
        case .healthKitAuthorizationDenied:
            return "HealthKit workout permission is required to start the bridge."
        case .liveActivitiesUnavailable:
            return "Live Activities are disabled for this app."
        }
    }
}
