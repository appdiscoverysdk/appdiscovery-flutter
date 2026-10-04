/// Optional per-call overrides for [AppDiscovery.showOfferwall].
class AppDiscoveryOfferwallOptions {
  final String? host;
  final String? trackerHost;
  final String? appId;
  final String? sdkKey;
  final String? playerId;

  const AppDiscoveryOfferwallOptions({
    this.host,
    this.trackerHost,
    this.appId,
    this.sdkKey,
    this.playerId,
  });

  Map<String, dynamic> toMap() => {
        if (host != null) 'host': host,
        if (trackerHost != null) 'trackerHost': trackerHost,
        if (appId != null) 'appId': appId,
        if (sdkKey != null) 'sdkKey': sdkKey,
        if (playerId != null) 'playerId': playerId,
      };
}
