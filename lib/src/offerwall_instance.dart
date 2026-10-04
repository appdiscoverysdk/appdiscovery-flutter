import 'dart:async';

import 'app_discovery.dart';
import 'host.dart';
import 'models/app_discovery_config.dart';
import 'models/app_discovery_reward.dart';

/// A configured offerwall that can be shown, mirroring the `Offerwall` object
/// of the native SDKs. Create one with [AppDiscovery.create].
class OfferwallInstance {
  /// Normalised host of the offerwall.
  final String host;

  /// Normalised tracker host, or `null` when it is the offerwall host.
  final String? trackerHost;
  final String appId;
  final String sdkKey;
  final String playerId;

  /// Called when the user completes an offer and earns a reward.
  void Function(AppDiscoveryReward reward)? onReward;

  /// Called when the user dismisses the offerwall.
  void Function()? onClose;

  StreamSubscription<AppDiscoveryReward>? _subReward;
  StreamSubscription<void>? _subClose;

  /// Throws an [ArgumentError] when [host] (or [trackerHost]) is not a valid
  /// host.
  OfferwallInstance({
    required String host,
    required this.appId,
    required this.sdkKey,
    required this.playerId,
    String? trackerHost,
  })  : host = normalizeHost(host),
        trackerHost = (trackerHost == null || trackerHost.trim().isEmpty)
            ? null
            : normalizeHost(trackerHost, setting: 'trackerHost');

  /// The current configuration.
  AppDiscoveryOfferwallConfig getConfig() {
    return AppDiscoveryOfferwallConfig(
      host: host,
      trackerHost: trackerHost,
      appId: appId,
      sdkKey: sdkKey,
      playerId: playerId,
      onReward: onReward,
      onClose: onClose,
    );
  }

  /// Shows the offerwall. Returns `false` when the platform could not
  /// present it.
  Future<bool> show() async {
    _removeListeners();

    if (onReward != null) {
      _subReward = AppDiscovery.onReward((reward) => onReward?.call(reward));
    }

    if (onClose != null) {
      _subClose = AppDiscovery.onClose(() {
        onClose?.call();
        _removeListeners();
      });
    }

    return AppDiscovery.showOfferwall(
      host: host,
      trackerHost: trackerHost,
      appId: appId,
      sdkKey: sdkKey,
      playerId: playerId,
    );
  }

  void _removeListeners() {
    _subReward?.cancel();
    _subReward = null;
    _subClose?.cancel();
    _subClose = null;
  }
}
