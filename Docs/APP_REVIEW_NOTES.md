# App Review Notes Draft

Paste and adapt this in App Store Connect under App Review Information.

```text
HR Bridge has no account system, no backend service, no in-app purchases, and no tracking SDKs.

Core functionality:
1. HR Glance starts a HealthKit workout session so iOS can provide live heart-rate samples from a compatible AirPods heart-rate source. The app displays BPM in the app, Live Activity, and Dynamic Island. The widget acts as a stable start/stop and monitoring indicator. When the user stops HR Glance, the workout is discarded.
2. BLE Bridge reads live heart rate during an active workout session and broadcasts it locally as a standard Bluetooth LE Heart Rate Service, so compatible bike computers and BLE heart-rate receivers can pair with it as a heart-rate sensor.
3. Demo Mode is included for review and screenshot/app preview capture. It is clearly labeled, generates simulated BPM locally, updates the app/widget/Live Activity, and advertises simulated BPM over the standard BLE Heart Rate Service. Demo Mode does not access HealthKit and is not a real measurement.
4. HR Glance can send a local high-heart-rate reminder when live BPM reaches 120+ BPM. This is a fitness reminder, not a medical alert.

How to review without compatible AirPods or a bike computer:
1. Open the app.
2. Tap Start Demo Mode.
3. Observe simulated BPM in the app.
4. Add the HR Glance widget, or view the existing widget, and confirm it shows Monitoring after starting.
5. View the Lock Screen or Dynamic Island Live Activity.
6. Optional: use any BLE scanner or heart-rate receiver to scan for AirPodsHRBridge and observe the Heart Rate Service with simulated BPM.
7. Return to the app and tap Stop Demo Mode.

How to review the real hardware flow:
1. Wear compatible AirPods with heart-rate support and keep them connected to the iPhone.
2. Tap Start HR Glance and grant HealthKit permissions if prompted.
3. Confirm live BPM appears in the app and Live Activity.
4. Stop HR Glance.
5. Tap Start BLE Bridge while the app is foregrounded and the iPhone is unlocked.
6. Wait until the app shows BPM and BLE is Advertising or Broadcasting.
7. On a compatible bike computer or BLE receiver, add a Heart Rate sensor and select AirPodsHRBridge.
8. Confirm the receiver displays BPM.
9. Stop BLE Bridge.

Privacy and data handling:
- Heart-rate data is read from HealthKit only after the user explicitly starts HR Glance or BLE Bridge.
- Demo Mode uses simulated BPM and does not read HealthKit.
- The app does not upload heart-rate data to any server.
- The app does not use heart-rate data for advertising, tracking, or analytics.
- During BLE Bridge or Demo Mode, BPM is broadcast locally over Bluetooth only while the user keeps the feature running.
- Widget state is stored locally on device so the widget can show the current state when the signing configuration supports shared storage.
- Local notifications are used only for user-visible high-heart-rate reminders.
- Workouts used for live heart-rate access are discarded when stopped.

This app is for fitness display and sensor interoperability. It is not a medical device and does not diagnose, treat, or provide medical advice.
```

Official references used while preparing these notes:

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/healthkit/protecting-user-privacy
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/
