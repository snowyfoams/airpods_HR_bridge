import Foundation
import CoreBluetooth
import Combine

final class BLEHeartRatePeripheral: NSObject, ObservableObject {
    @Published private(set) var status = "Idle"
    @Published private(set) var subscriberCount = 0

    private let localName: String
    private var peripheralManager: CBPeripheralManager!
    private var heartRateService: CBMutableService?
    private var heartRateMeasurement: CBMutableCharacteristic?
    private var pendingBPM: Int?
    private var shouldAdvertise = false
    private var subscribedCentrals = Set<UUID>()
    private var lastNotificationDate: Date?
    private var pendingNotificationTimer: Timer?

    private let heartRateServiceUUID = CBUUID(string: "180D")
    private let heartRateMeasurementUUID = CBUUID(string: "2A37")
    private let bodySensorLocationUUID = CBUUID(string: "2A38")
    private let minimumNotificationInterval: TimeInterval = 1.0

    init(localName: String) {
        self.localName = localName
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    }

    func start() {
        shouldAdvertise = true
        guard peripheralManager.state == .poweredOn else {
            status = "Waiting for Bluetooth: \(stateDescription(peripheralManager.state))"
            return
        }
        configureServiceAndAdvertise()
    }

    func prepareForFirstMeasurement() {
        shouldAdvertise = false
        if peripheralManager.state == .poweredOn {
            peripheralManager.stopAdvertising()
            peripheralManager.removeAllServices()
        }
        heartRateService = nil
        heartRateMeasurement = nil
        pendingBPM = nil
        pendingNotificationTimer?.invalidate()
        pendingNotificationTimer = nil
        lastNotificationDate = nil
        subscribedCentrals.removeAll()
        subscriberCount = 0
        status = "Waiting for first BPM"
    }

    func stop() {
        shouldAdvertise = false
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        heartRateService = nil
        heartRateMeasurement = nil
        pendingBPM = nil
        pendingNotificationTimer?.invalidate()
        pendingNotificationTimer = nil
        lastNotificationDate = nil
        subscribedCentrals.removeAll()
        subscriberCount = 0
        status = "Stopped"
    }

    func updateHeartRate(_ bpm: Int) {
        guard (1...254).contains(bpm) else { return }
        pendingBPM = bpm
        sendHeartRateIfPossible(bpm)
    }

    private func configureServiceAndAdvertise() {
        status = "Configuring BLE service"
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()

        let measurement = CBMutableCharacteristic(type: heartRateMeasurementUUID,
                                                   properties: [.notify],
                                                   value: nil,
                                                   permissions: [])

        // BLE Body Sensor Location values: 0 other, 1 chest, 2 wrist, 3 finger, 4 hand, 5 ear lobe, 6 foot.
        // AirPods are in-ear, so ear lobe is the closest standard value.
        let bodyLocationValue = Data([0x05])
        let bodyLocation = CBMutableCharacteristic(type: bodySensorLocationUUID,
                                                    properties: [.read],
                                                    value: bodyLocationValue,
                                                    permissions: [.readable])

        let service = CBMutableService(type: heartRateServiceUUID, primary: true)
        service.characteristics = [measurement, bodyLocation]
        self.heartRateMeasurement = measurement
        self.heartRateService = service
        peripheralManager.add(service)
    }

    private func startAdvertising() {
        let advertisement: [String: Any] = [
            CBAdvertisementDataLocalNameKey: localName,
            CBAdvertisementDataServiceUUIDsKey: [heartRateServiceUUID]
        ]
        peripheralManager.startAdvertising(advertisement)
        status = "Advertising as \(localName)"
    }

    private func sendHeartRateIfPossible(_ bpm: Int) {
        guard let characteristic = heartRateMeasurement else { return }
        guard subscriberCount > 0 else { return }

        let now = Date()
        if let lastNotificationDate {
            let elapsed = now.timeIntervalSince(lastNotificationDate)
            if elapsed < minimumNotificationInterval {
                pendingBPM = bpm
                schedulePendingNotification(after: minimumNotificationInterval - elapsed)
                return
            }
        }

        // Bluetooth Heart Rate Measurement:
        // Flags = 0x06 -> UInt8 BPM, sensor contact supported and detected.
        let flags: UInt8 = 0b0000_0110
        let hr = UInt8(clamping: bpm)
        let data = Data([flags, hr])

        let didSend = peripheralManager.updateValue(data,
                                                    for: characteristic,
                                                    onSubscribedCentrals: nil)
        if didSend {
            status = "Broadcasting \(bpm) BPM"
            pendingBPM = nil
            lastNotificationDate = now
            pendingNotificationTimer?.invalidate()
            pendingNotificationTimer = nil
        } else {
            status = "BLE buffer full"
            pendingBPM = bpm
        }
    }

    private func schedulePendingNotification(after delay: TimeInterval) {
        pendingNotificationTimer?.invalidate()
        pendingNotificationTimer = Timer.scheduledTimer(withTimeInterval: max(0.05, delay),
                                                        repeats: false) { [weak self] _ in
            guard let self, let pendingBPM = self.pendingBPM else { return }
            self.pendingNotificationTimer = nil
            self.sendHeartRateIfPossible(pendingBPM)
        }
    }

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "powered off"
        case .poweredOn: return "powered on"
        @unknown default: return "unknown"
        }
    }
}

extension BLEHeartRatePeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        status = stateDescription(peripheral.state)
        if peripheral.state == .poweredOn {
            if shouldAdvertise {
                configureServiceAndAdvertise()
            } else {
                status = "Bluetooth ready"
            }
        } else if shouldAdvertise {
            status = "Waiting for Bluetooth: \(stateDescription(peripheral.state))"
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            status = "Add service error: \(error.localizedDescription)"
            return
        }
        startAdvertising()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            status = "Advertising error: \(error.localizedDescription)"
        } else {
            status = "Advertising as \(localName)"
            if let pendingBPM { sendHeartRateIfPossible(pendingBPM) }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        subscribedCentrals.insert(central.identifier)
        subscriberCount = subscribedCentrals.count
        status = "Subscribed"
        if let pendingBPM { sendHeartRateIfPossible(pendingBPM) }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals.remove(central.identifier)
        subscriberCount = subscribedCentrals.count
        status = subscriberCount == 0 ? "Advertising" : "Subscribed"
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        if let pendingBPM { sendHeartRateIfPossible(pendingBPM) }
    }
}
