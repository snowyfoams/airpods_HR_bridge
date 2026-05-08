# App Store Demo Plan

Use these demos for App Store screenshots, app previews, and App Review notes. Avoid showing real personal health history. If you show a bike computer or BLE scanner, keep the shot focused on pairing behavior rather than third-party branding.

## Demo Mode Flow

Demo Mode is the safest capture path because it does not require AirPods heart-rate data or HealthKit authorization.

1. Open HR Bridge.
2. Tap Start Demo Mode.
3. Confirm the app BPM changes every few seconds.
4. Add or view the HR Glance widget and confirm it changes from Check HR to Monitoring.
5. Open the Lock Screen or Dynamic Island and show the Live Activity.
6. Optional: scan from a BLE heart-rate receiver or BLE scanner and show the standard Heart Rate Service with simulated BPM.
7. Return to the app and tap Stop Demo Mode.

## App Preview Storyboard

Target length: 20-25 seconds.

1. 0-3s: Show the app home screen with the BPM display and three clear actions.
2. 3-7s: Tap Start Demo Mode and show simulated BPM entering Normal.
3. 7-12s: Show the Home Screen widget switching to Monitoring.
4. 12-17s: Show the Lock Screen or Dynamic Island Live Activity.
5. 17-22s: Show BLE pairing or a BLE scanner receiving simulated HR.
6. 22-25s: Return to the app and stop Demo Mode.

Do not present Demo Mode as a real measurement. The visual message should be: this is a hardware-dependent heart-rate bridge, and the demo simulates the flow for review and explanation.

## Real Hardware Demo

Use this for a separate App Review support video or a longer product demo.

1. Wear compatible AirPods and keep them connected to the iPhone.
2. Open the app and tap Start HR Glance.
3. Show the HealthKit prompt, if it appears, then show BPM in the app.
4. Show the Live Activity or Dynamic Island with live BPM.
5. Stop HR Glance and note that the workout is discarded.
6. Start BLE Bridge with the app foregrounded and the iPhone unlocked.
7. Wait until the app shows BPM and BLE is Advertising or Broadcasting.
8. On the bike computer: Add Sensor -> Heart Rate -> select AirPodsHRBridge.
9. Show the bike computer displaying BPM.
10. Stop BLE Bridge.

## Screenshot Shot List

Upload 4-6 screenshots.

1. App home screen with BPM and actions.
2. HR Glance or Demo Mode running with live BPM.
3. Widget showing Monitoring.
4. Lock Screen Live Activity or Dynamic Island.
5. BLE Bridge ready to pair as a Bluetooth heart-rate sensor.
6. Optional: BLE receiver or bike computer paired to AirPodsHRBridge.

## Apple Asset Constraints

As of May 8, 2026:

- Screenshots: Apple accepts 1-10 screenshots per device size in `.png`, `.jpg`, or `.jpeg`.
- Highest iPhone display family can be supplied at 6.9-inch sizes such as 1260 x 2736, 1290 x 2796, or 1320 x 2868 portrait.
- App previews are optional; up to 3 can be uploaded per device size and language.
- App previews must be 15-30 seconds, up to 500 MB, and no more than 30 fps.
- H.264 `.mov`, `.m4v`, or `.mp4` is accepted; ProRes 422 HQ `.mov` is also accepted.

Official references:

- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/
- https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
