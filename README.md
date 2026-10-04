# AppDiscovery SDK for Flutter

A Flutter plugin that adds an offerwall to your Android and iOS app. Your users earn rewards by completing offers, and your app is notified through simple callbacks.

The SDK is configured with the host of your own offerwall (given to you by the network you publish for). There is no default host.

## Requirements

| Requirement | Version |
|---|---|
| Flutter | 3.3+ (Dart 3) |
| Android minSdk | 21, Java 17 |
| iOS deployment target | 13.0+ |

## Installation

Add the package as a git dependency in `pubspec.yaml`:

```yaml
dependencies:
  appdiscovery_sdk:
    git:
      url: https://github.com/appdiscoverysdk/appdiscovery-flutter.git
      ref: 1.0.0
```

Then run `flutter pub get`. (A pub.dev release will follow.)

**Android.** The native SDK is served from JitPack; the plugin adds the repository itself. If your build declares repositories centrally (`dependencyResolutionManagement` with `FAIL_ON_PROJECT_REPOS`), add it there:

```kotlin
maven { url = uri("https://jitpack.io") }
```

The permissions (`INTERNET`, `ACCESS_NETWORK_STATE`, `AD_ID`) and the offerwall activity are merged automatically.

**iOS.** The native iOS SDK is bundled with the plugin. Run `pod install` (done by `flutter run`). The plugin integrates through CocoaPods; Swift Package Manager based Flutter builds fall back to CocoaPods for this plugin.

## Quick start

```dart
import 'package:appdiscovery_sdk/appdiscovery_sdk.dart';

Future<void> setUp() async {
  await AppDiscovery.init(
    host: 'offers.example.com',   // Host of your offerwall (required)
    appId: 'YOUR_APP_ID',
    sdkKey: 'YOUR_SDK_KEY',
    playerId: 'player_123',       // Unique id of the player in your app
  );

  AppDiscovery.onReward((reward) {
    print('Reward ${reward.amount}, transaction ${reward.txid}');
  });
  AppDiscovery.onClose(() => print('Offerwall closed'));
}

Future<void> openOfferwall() => AppDiscovery.showOfferwall();
```

Or create a self-contained instance, like the native `AppDiscovery.create`:

```dart
final offerwall = AppDiscovery.create(
  host: 'offers.example.com',
  appId: 'YOUR_APP_ID',
  sdkKey: 'YOUR_SDK_KEY',
  playerId: 'player_123',
)
  ..onReward = (reward) => print(reward.amount)
  ..onClose = () => print('closed');

await offerwall.show();
```

## API

### AppDiscovery

| Member | Description |
|---|---|
| `init({host, appId, sdkKey, playerId, trackerHost})` | Stores the configuration. `host` is a plain host name (an `https://` URL is accepted). Throws an `ArgumentError` when it is missing or invalid. `trackerHost` is only needed when reward sync runs on a different host. |
| `initFromConfig(AppDiscoveryConfig)` | Same, from a config object. |
| `create({host, appId, sdkKey, playerId, trackerHost})` | Returns an `OfferwallInstance`. |
| `setUserId(playerId)` | Changes the active player, for example after a login. |
| `showOfferwall({host, trackerHost, appId, sdkKey, playerId})` | Shows the offerwall. Values you leave out come from `init`. Returns `false` when `appId` or `sdkKey` is missing or the platform could not present it. |
| `showOfferwallWithOptions(AppDiscoveryOfferwallOptions?)` | Same, with an options object. |
| `syncPendingRewards({...})` | Delivers rewards earned while the app was closed and returns them. |
| `onReward(callback)` / `onClose(callback)` | Subscriptions; cancel the returned `StreamSubscription` when done. |
| `rewardStream` / `closeStream` | The broadcast streams behind them. |
| `removeAllListeners()` | Cancels every subscription made with `onReward` / `onClose`. |
| `getHost()`, `getTrackerHost()`, `getAppId()`, `getSdkKey()`, `getPlayerId()`, `isInitialized()` | Read the stored configuration. |

### AppDiscoveryReward

| Field | Description |
|---|---|
| `amount` | Reward amount |
| `txid` | Unique transaction id, use it to avoid crediting twice |
| `status` | `approved`, `pending`, `reversed` or `rejected` |
| `playerId`, `publisherId`, `timestamp`, `type` | Optional metadata |
| `raw`, `reward['click_id']` | The full payload; any additional parameter sent by the server is preserved |

## Troubleshooting

- **`ArgumentError` mentioning `host`:** `host` must be a plain host name such as `offers.example.com` (or an `https://` URL). Cleartext `http://` is rejected.
- **Zero offers shown:** check that the application id matches the one registered for your `appId`, that `appId`, `sdkKey` and `host` are correct, and that `playerId` is not empty.
- **`showOfferwall` returns `false`:** the reason is printed in the debug console (for example no foreground activity yet).

## Example

See [`example/`](example/).

## License

MIT, see [LICENSE](LICENSE).
