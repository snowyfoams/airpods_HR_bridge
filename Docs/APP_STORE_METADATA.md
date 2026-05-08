# App Store Metadata Draft

## Naming Note

Apple's marketing guidance prefers Apple product names in referential phrases, such as "for iPhone" or "compatible with". For App Store submission, consider using a name like `HR Bridge for AirPods` instead of leading with `AirPods` as the product name. Keep the final name under Apple's 30-character app-name limit.

## Name Options

1. HR Bridge for AirPods
2. Heart Rate Bridge
3. HR Glance Bridge

Recommended: `HR Bridge for AirPods`

## Subtitle Options

1. Bluetooth HR for bike computers
2. Live HR glance and BLE bridge
3. Heart rate to BLE sensors

Recommended: `Bluetooth HR for bike computers`

## Promotional Text

Turn compatible AirPods heart-rate data into a live glance and a standard Bluetooth heart-rate sensor for fitness devices.

## Description

HR Bridge for AirPods helps you use compatible AirPods heart-rate data during workouts.

Start HR Glance to view live BPM in the app, on the Lock Screen, and in the Dynamic Island. Use the Home Screen widget as a one-tap start/stop control and monitoring indicator. Stop when you are done and the workout session is discarded, so it does not clutter your Health history.

Start BLE Bridge to broadcast live BPM as a standard Bluetooth LE Heart Rate Service. Compatible bike computers and BLE heart-rate receivers can pair with it like a normal heart-rate sensor.

Features:

- Live heart-rate display from HealthKit workout metrics
- Lock Screen and Dynamic Island Live Activity
- One-tap HR Glance widget for start/stop and monitoring state
- Local high-heart-rate reminders
- Bluetooth LE Heart Rate Service broadcasting
- Demo Mode for setup, review, and troubleshooting without hardware
- No account, no server upload, no tracking SDK

Requirements:

- iPhone
- Compatible AirPods heart-rate source
- Health permission for heart-rate and workout access
- Optional Bluetooth heart-rate receiver or bike computer for bridge mode

This app is for fitness display and sensor interoperability. It is not a medical device and does not diagnose, treat, or provide medical advice.

## Keywords

heart rate,bluetooth,cycling,fitness,workout,HRM,BLE,widget,live activity,bike computer

## Privacy Summary

The app reads heart-rate data from HealthKit only after the user starts HR Glance or BLE Bridge. It does not upload heart-rate data to a server, does not track users, and does not use health data for advertising. When BLE Bridge is running, BPM is broadcast locally over Bluetooth so the user's chosen receiver can display it.

## Support URL

Use the GitHub repository, a simple support page, or a Notion/static page that includes:

- Setup requirements
- HealthKit permission explanation
- BLE Bridge pairing steps
- Widget and Live Activity notes
- Contact email

## Privacy Policy URL

Required in App Store Connect. Publish `Docs/PRIVACY_POLICY_DRAFT.md` or equivalent as a public URL before submission.

Official references:

- https://developer.apple.com/app-store/marketing/guidelines/
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/app-privacy-details/
