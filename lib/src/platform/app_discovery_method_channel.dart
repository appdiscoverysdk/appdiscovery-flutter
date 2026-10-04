import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_discovery_reward.dart';
import 'app_discovery_platform_interface.dart';

/// Channel names shared with the Android and iOS plugin code.
const String appDiscoveryMethodChannelName = 'com.appdiscoverysdk.flutter/methods';
const String appDiscoveryEventChannelName = 'com.appdiscoverysdk.flutter/events';

/// [AppDiscoveryPlatform] that talks to the native plugins over a method
/// channel (calls) and an event channel (reward and close events).
class MethodChannelAppDiscovery extends AppDiscoveryPlatform {
  @visibleForTesting
  final MethodChannel methodChannel =
      const MethodChannel(appDiscoveryMethodChannelName);

  @visibleForTesting
  final EventChannel eventChannel =
      const EventChannel(appDiscoveryEventChannelName);

  final StreamController<AppDiscoveryReward> _rewards =
      StreamController<AppDiscoveryReward>.broadcast();
  final StreamController<void> _closes = StreamController<void>.broadcast();
  StreamSubscription<dynamic>? _nativeEvents;

  /// One native subscription feeds both streams, so every event is delivered
  /// exactly once.
  void _ensureListening() {
    _nativeEvents ??= eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        switch (event['event']?.toString()) {
          case 'onReward':
            final data = event['data'];
            if (data is Map) _rewards.add(AppDiscoveryReward.fromMap(data));
            break;
          case 'onClose':
            _closes.add(null);
            break;
        }
      },
      onError: (Object err) {
        debugPrint('[AppDiscovery SDK] Event channel error: $err');
      },
    );
  }

  Future<bool> _invokeBool(String method, Map<String, dynamic> args) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(method, args);
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint('[AppDiscovery SDK] $method failed (${e.code}): ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('[AppDiscovery SDK] $method is not available on this platform: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> initSDK({
    required String host,
    required String appId,
    required String sdkKey,
    String? playerId,
    String? trackerHost,
  }) {
    return _invokeBool('initSDK', {
      'host': host,
      'trackerHost': trackerHost,
      'appId': appId,
      'sdkKey': sdkKey,
      'playerId': playerId ?? '',
    });
  }

  @override
  Future<bool> setUserId(String playerId) {
    return _invokeBool('setUserId', {'playerId': playerId});
  }

  @override
  Future<bool> showOfferwall({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) {
    _ensureListening();
    return _invokeBool('showOfferwall', {
      'host': host,
      'trackerHost': trackerHost,
      'appId': appId,
      'sdkKey': sdkKey,
      'playerId': playerId,
    });
  }

  @override
  Future<List<AppDiscoveryReward>> syncPendingRewards({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) async {
    try {
      final result = await methodChannel
          .invokeListMethod<Map<dynamic, dynamic>>('syncPendingRewards', {
        'host': host,
        'trackerHost': trackerHost,
        'appId': appId,
        'sdkKey': sdkKey,
        'playerId': playerId,
      });
      return (result ?? const <Map<dynamic, dynamic>>[])
          .map(AppDiscoveryReward.fromMap)
          .toList();
    } on PlatformException catch (e) {
      debugPrint('[AppDiscovery SDK] syncPendingRewards failed (${e.code}): ${e.message}');
      return const <AppDiscoveryReward>[];
    } on MissingPluginException catch (e) {
      debugPrint('[AppDiscovery SDK] syncPendingRewards is not available on this platform: ${e.message}');
      return const <AppDiscoveryReward>[];
    }
  }

  @override
  Stream<AppDiscoveryReward> get onRewardStream {
    _ensureListening();
    return _rewards.stream;
  }

  @override
  Stream<void> get onCloseStream {
    _ensureListening();
    return _closes.stream;
  }
}
