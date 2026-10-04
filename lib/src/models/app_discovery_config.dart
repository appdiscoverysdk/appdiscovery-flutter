import 'app_discovery_reward.dart';

/// Configuration for [AppDiscovery.init].
class AppDiscoveryConfig {
  /// Host of your offerwall web app, for example `offers.example.com`
  /// (an `https://` URL is accepted too). Required, there is no default.
  final String host;

  /// Host of the tracker, when reward sync runs on a different host than the
  /// offerwall. Defaults to [host].
  final String? trackerHost;

  /// Your app ID from the dashboard.
  final String appId;

  /// Your SDK key from the dashboard.
  final String sdkKey;

  /// The unique player / user ID. Can be set later with `setUserId`.
  final String? playerId;

  const AppDiscoveryConfig({
    required this.host,
    required this.appId,
    required this.sdkKey,
    this.playerId,
    this.trackerHost,
  });

  Map<String, dynamic> toMap() => {
        'host': host,
        'trackerHost': trackerHost,
        'appId': appId,
        'sdkKey': sdkKey,
        'playerId': playerId,
      };
}

/// Configuration of one [OfferwallInstance].
class AppDiscoveryOfferwallConfig extends AppDiscoveryConfig {
  /// Called when the user earns a reward.
  final void Function(AppDiscoveryReward reward)? onReward;

  /// Called when the offerwall is dismissed.
  final void Function()? onClose;

  const AppDiscoveryOfferwallConfig({
    required super.host,
    required super.appId,
    required super.sdkKey,
    required String playerId,
    super.trackerHost,
    this.onReward,
    this.onClose,
  }) : super(playerId: playerId);
}
