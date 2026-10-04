# Changelog

## 1.0.0

- First public release of the AppDiscovery Flutter SDK (Android and iOS).
- `AppDiscovery.init(host:, appId:, sdkKey:, playerId:, trackerHost:)`: the offerwall host is a required setting, there is no default. An invalid host throws an `ArgumentError`.
- `AppDiscovery.create(...)` returns an `OfferwallInstance` with `show()`, `onReward` and `onClose`, like the native `AppDiscovery.create`.
- `AppDiscovery.showOfferwall`, `setUserId`, `onReward` / `onClose` subscriptions and `rewardStream` / `closeStream`.
- `AppDiscovery.syncPendingRewards` delivers rewards earned while the app was closed.
- Builds on the AppDiscovery Android SDK 1.0.0 (JitPack) and the AppDiscovery iOS SDK 1.0.0 (xcframework, vendored).
