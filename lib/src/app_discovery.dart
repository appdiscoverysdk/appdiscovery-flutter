import 'dart:async';

import 'package:flutter/foundation.dart';

import 'host.dart';
import 'models/app_discovery_config.dart';
import 'models/app_discovery_options.dart';
import 'models/app_discovery_reward.dart';
import 'offerwall_instance.dart';
import 'platform/app_discovery_platform_interface.dart';

/// Entry point of the AppDiscovery offerwall SDK.
///
/// Every integration points the SDK at its own offerwall, so [host] is a
/// required setting and there is no default.
///
/// ```dart
/// await AppDiscovery.init(
///   host: 'offers.example.com',
///   appId: 'YOUR_APP_ID',
///   sdkKey: 'YOUR_SDK_KEY',
///   playerId: 'player_123',
/// );
/// AppDiscovery.onReward((reward) => print(reward.amount));
/// await AppDiscovery.showOfferwall();
/// ```
class AppDiscovery {
  AppDiscovery._();

  static String _host = '';
  static String? _trackerHost;
  static String _appId = '';
  static String _sdkKey = '';
  static String _playerId = '';
  static bool _isInitialized = false;

  static final List<StreamSubscription<AppDiscoveryReward>> _rewardSubscriptions = [];
  static final List<StreamSubscription<void>> _closeSubscriptions = [];

  /// Initializes the SDK and stores the configuration.
  ///
  /// [host] is the host of your offerwall (for example `offers.example.com`;
  /// an `https://` URL is accepted). Throws an [ArgumentError] when it is
  /// missing or is not a plain host name. [trackerHost] is only needed when
  /// reward sync runs on a different host than the offerwall.
  static Future<bool> init({
    required String host,
    required String appId,
    required String sdkKey,
    String? playerId,
    String? trackerHost,
  }) async {
    final normalizedHost = normalizeHost(host);
    final normalizedTracker = _normalizeOptionalHost(trackerHost);

    _host = normalizedHost;
    _trackerHost = normalizedTracker;
    _appId = appId.trim();
    _sdkKey = sdkKey.trim();
    _playerId = (playerId ?? '').trim();
    _isInitialized = true;

    return AppDiscoveryPlatform.instance.initSDK(
      host: _host,
      trackerHost: _trackerHost,
      appId: _appId,
      sdkKey: _sdkKey,
      playerId: _playerId,
    );
  }

  /// Initializes the SDK from an [AppDiscoveryConfig].
  static Future<bool> initFromConfig(AppDiscoveryConfig config) {
    return init(
      host: config.host,
      trackerHost: config.trackerHost,
      appId: config.appId,
      sdkKey: config.sdkKey,
      playerId: config.playerId,
    );
  }

  /// Creates an [OfferwallInstance] with its own configuration, the
  /// equivalent of `AppDiscovery.create(...)` in the native SDKs.
  ///
  /// Throws an [ArgumentError] when [host] (or [trackerHost]) is not a valid
  /// host.
  static OfferwallInstance create({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) {
    return OfferwallInstance(
      host: host,
      trackerHost: trackerHost,
      appId: appId,
      sdkKey: sdkKey,
      playerId: playerId,
    );
  }

  /// Updates the active player / user ID.
  static Future<bool> setUserId(String playerId) {
    _playerId = playerId.trim();
    return AppDiscoveryPlatform.instance.setUserId(_playerId);
  }

  /// Shows the offerwall. Values not passed here come from [init].
  ///
  /// Returns `false` when `appId` or `sdkKey` is missing or the platform
  /// could not present the offerwall. Throws an [ArgumentError] when the host
  /// is missing or is not a valid host.
  static Future<bool> showOfferwall({
    String? host,
    String? trackerHost,
    String? appId,
    String? sdkKey,
    String? playerId,
  }) async {
    final effectiveHost = normalizeHost(_firstNonEmpty(host, _host));
    final effectiveTracker =
        _normalizeOptionalHost(trackerHost) ?? (host == null ? _trackerHost : null);
    final effectiveAppId = _firstNonEmpty(appId, _appId);
    final effectiveSdkKey = _firstNonEmpty(sdkKey, _sdkKey);
    final effectivePlayerId = _firstNonEmpty(playerId, _playerId);

    if (effectiveAppId.isEmpty || effectiveSdkKey.isEmpty) {
      debugPrint('[AppDiscovery SDK] Error: appId and sdkKey are required before showing the offerwall.');
      return false;
    }
    if (effectivePlayerId.isEmpty) {
      debugPrint('[AppDiscovery SDK] Warning: playerId is empty. Make sure the user is logged in or the playerId is set.');
    }

    return AppDiscoveryPlatform.instance.showOfferwall(
      host: effectiveHost,
      trackerHost: effectiveTracker,
      appId: effectiveAppId,
      sdkKey: effectiveSdkKey,
      playerId: effectivePlayerId,
    );
  }

  /// Shows the offerwall with an optional [AppDiscoveryOfferwallOptions].
  static Future<bool> showOfferwallWithOptions([AppDiscoveryOfferwallOptions? options]) {
    return showOfferwall(
      host: options?.host,
      trackerHost: options?.trackerHost,
      appId: options?.appId,
      sdkKey: options?.sdkKey,
      playerId: options?.playerId,
    );
  }

  /// Delivers rewards the player earned while the app was closed, without
  /// opening the offerwall. Returns the rewards that were found.
  ///
  /// The native SDK also hands these rewards to the `onReward` listener of an
  /// offerwall that was shown earlier in this session; do not credit a `txid`
  /// twice.
  static Future<List<AppDiscoveryReward>> syncPendingRewards({
    String? host,
    String? trackerHost,
    String? appId,
    String? sdkKey,
    String? playerId,
  }) async {
    final effectiveHost = normalizeHost(_firstNonEmpty(host, _host));
    final effectiveTracker =
        _normalizeOptionalHost(trackerHost) ?? (host == null ? _trackerHost : null);
    final effectiveAppId = _firstNonEmpty(appId, _appId);
    final effectiveSdkKey = _firstNonEmpty(sdkKey, _sdkKey);
    final effectivePlayerId = _firstNonEmpty(playerId, _playerId);

    if (effectiveAppId.isEmpty || effectiveSdkKey.isEmpty || effectivePlayerId.isEmpty) {
      debugPrint('[AppDiscovery SDK] Error: appId, sdkKey and playerId are required to sync rewards.');
      return const <AppDiscoveryReward>[];
    }

    return AppDiscoveryPlatform.instance.syncPendingRewards(
      host: effectiveHost,
      trackerHost: effectiveTracker,
      appId: effectiveAppId,
      sdkKey: effectiveSdkKey,
      playerId: effectivePlayerId,
    );
  }

  /// Subscribes to reward events. Cancel the returned subscription when done.
  static StreamSubscription<AppDiscoveryReward> onReward(
      void Function(AppDiscoveryReward reward) callback) {
    final subscription = AppDiscoveryPlatform.instance.onRewardStream.listen(
      callback,
      onError: (Object err) {
        debugPrint('[AppDiscovery SDK] Exception in onReward stream: $err');
      },
    );
    _rewardSubscriptions.add(subscription);
    return subscription;
  }

  /// Subscribes to offerwall close events. Cancel the returned subscription
  /// when done.
  static StreamSubscription<void> onClose(void Function() callback) {
    final subscription = AppDiscoveryPlatform.instance.onCloseStream.listen(
      (_) => callback(),
      onError: (Object err) {
        debugPrint('[AppDiscovery SDK] Exception in onClose stream: $err');
      },
    );
    _closeSubscriptions.add(subscription);
    return subscription;
  }

  /// Broadcast stream of reward events.
  static Stream<AppDiscoveryReward> get rewardStream =>
      AppDiscoveryPlatform.instance.onRewardStream;

  /// Broadcast stream of close events.
  static Stream<void> get closeStream =>
      AppDiscoveryPlatform.instance.onCloseStream;

  /// Updates stored configuration at runtime. A new [host] or [trackerHost]
  /// is validated like in [init].
  static void setConfig({
    String? host,
    String? trackerHost,
    String? appId,
    String? sdkKey,
    String? playerId,
  }) {
    if (host != null) _host = normalizeHost(host);
    if (trackerHost != null) _trackerHost = _normalizeOptionalHost(trackerHost);
    if (appId != null) _appId = appId.trim();
    if (sdkKey != null) _sdkKey = sdkKey.trim();
    if (playerId != null) setUserId(playerId);
  }

  /// The configured offerwall host (empty before [init]).
  static String getHost() => _host;

  /// The configured tracker host, or `null` when it is the offerwall host.
  static String? getTrackerHost() => _trackerHost;

  static String getAppId() => _appId;

  static String getSdkKey() => _sdkKey;

  static String getPlayerId() => _playerId;

  /// Whether [init] has been called.
  static bool isInitialized() => _isInitialized;

  /// Cancels every subscription created with [onReward] and [onClose].
  static void removeAllListeners() {
    for (final sub in _rewardSubscriptions) {
      sub.cancel();
    }
    _rewardSubscriptions.clear();

    for (final sub in _closeSubscriptions) {
      sub.cancel();
    }
    _closeSubscriptions.clear();
  }

  static String _firstNonEmpty(String? preferred, String fallback) {
    final p = preferred?.trim() ?? '';
    return p.isNotEmpty ? p : fallback;
  }

  static String? _normalizeOptionalHost(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return normalizeHost(raw, setting: 'trackerHost');
  }

  /// Resets the stored configuration. For tests only.
  @visibleForTesting
  static void resetForTesting() {
    removeAllListeners();
    _host = '';
    _trackerHost = null;
    _appId = '';
    _sdkKey = '';
    _playerId = '';
    _isInitialized = false;
  }
}
