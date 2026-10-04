import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/app_discovery_reward.dart';
import 'app_discovery_method_channel.dart';

/// The platform interface of the plugin. Implemented by the method channel in
/// production and replaced by a fake in tests.
abstract class AppDiscoveryPlatform extends PlatformInterface {
  AppDiscoveryPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppDiscoveryPlatform _instance = MethodChannelAppDiscovery();

  static AppDiscoveryPlatform get instance => _instance;

  static set instance(AppDiscoveryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> initSDK({
    required String host,
    required String appId,
    required String sdkKey,
    String? playerId,
    String? trackerHost,
  }) {
    throw UnimplementedError('initSDK() has not been implemented.');
  }

  Future<bool> setUserId(String playerId) {
    throw UnimplementedError('setUserId() has not been implemented.');
  }

  Future<bool> showOfferwall({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) {
    throw UnimplementedError('showOfferwall() has not been implemented.');
  }

  Future<List<AppDiscoveryReward>> syncPendingRewards({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) {
    throw UnimplementedError('syncPendingRewards() has not been implemented.');
  }

  Stream<AppDiscoveryReward> get onRewardStream {
    throw UnimplementedError('onRewardStream has not been implemented.');
  }

  Stream<void> get onCloseStream {
    throw UnimplementedError('onCloseStream has not been implemented.');
  }
}
