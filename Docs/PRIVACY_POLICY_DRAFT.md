# Privacy Policy Draft

Last updated: May 8, 2026

This privacy policy describes how HR Bridge for AirPods handles data.

## Data the App Accesses

The app may request permission to read heart-rate data and workout data from Apple Health through HealthKit. The app may also request permission to write workout sessions because iOS requires an active workout session for live workout heart-rate metrics.

## How the App Uses Health Data

The app uses heart-rate data only for these user-initiated features:

- HR Glance: display live BPM in the app, Live Activity, and Dynamic Island, and show monitoring state in the widget.
- Edge Bridge: broadcast live BPM locally as a Bluetooth LE Heart Rate Service so a compatible receiver can display it.

When a session stops, the app discards the workout session it used for live heart-rate access.

## Demo Mode

Demo Mode generates simulated BPM locally. It does not read HealthKit and is not a real heart-rate measurement.

## Data Sharing

The app does not upload heart-rate data to a server.

The app does not sell health data.

The app does not use health data for advertising, tracking, or analytics.

When Edge Bridge or Demo Mode is running, BPM is broadcast locally over Bluetooth so nearby compatible receivers selected by the user can read it. The user controls when broadcasting starts and stops.

## Local Storage

The app stores temporary widget state locally on device so the widget can show whether monitoring is active when the signing configuration supports shared storage. This state is not sent to a server.

The app may send local notifications for high-heart-rate reminders. Notification content is generated on device and is not sent to a server.

## Third-Party SDKs

The app does not include third-party analytics, advertising, or tracking SDKs.

## User Control

Users can stop HR Glance, Edge Bridge, or Demo Mode at any time in the app. Users can also manage or revoke Health permissions in the iOS Settings app or Apple Health app.

## Medical Disclaimer

The app is for fitness display and sensor interoperability. It is not a medical device and does not diagnose, treat, or provide medical advice.

## Contact

Replace this line with your support email or support URL before publishing this policy.
