# ANT+ route: external bridge required

The iPhone app cannot transmit ANT+ natively. ANT+ is a separate 2.4 GHz protocol and iOS exposes Bluetooth LE through CoreBluetooth, not an ANT+ transmitter stack.

A practical ANT+ architecture is:

```text
AirPods Pro 3
  -> iPhone app: HealthKit live workout HR
  -> iPhone app: BLE Heart Rate Service, UUID 0x180D / 0x2A37
  -> external bridge: nRF52/nRF53 listens as BLE central
  -> external bridge: ANT+ Heart Rate Monitor transmitter
  -> Garmin Edge pairs as ANT+ HR sensor
```

## Hardware options

- Nordic nRF5340 DK: closest to current official ANT for nRF Connect SDK examples.
- nRF52840-based hardware may be feasible depending on the ANT stack / SDK you choose, but check SDK and licensing constraints before committing PCB work.
- ANT USB-m connected to Linux/Raspberry Pi can be used for lab prototypes, but it is less suitable for a compact cycling setup.

## Firmware modules

1. BLE central scanner:
   - Scan for Heart Rate Service `0x180D`.
   - Connect to `AirPodsHRBridge`.
   - Subscribe to Heart Rate Measurement `0x2A37`.
   - Parse packet: first byte flags; if bit 0 = 0, BPM is UInt8 at byte 1.

2. ANT+ HRM transmitter:
   - Device profile: Heart Rate Monitor.
   - Channel: master/transmit.
   - Typical public ANT+ HRM parameters in Nordic example:
     - RF channel: 57 / 2457 MHz
     - Device type: 0x78 / 120
     - Channel period: 8070 / about 4.06 Hz
   - Send page 4 as main HR data page; rotate background pages if needed for full interoperability.

3. Safety / sanity:
   - Timeout HR if no BLE update for >3 s.
   - Clamp BPM to 1...254.
   - Use a stable ANT device number so Garmin remembers the sensor.

## Development path

- Phase 1: Run Nordic ANT+ HRM TX sample with fixed BPM; verify Garmin discovers it as ANT+ HR.
- Phase 2: Add BLE central code and parse iPhone HRS data.
- Phase 3: Replace fixed BPM with live BLE BPM.
- Phase 4: Package in a battery-powered board.

