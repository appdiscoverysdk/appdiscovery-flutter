import 'dart:async';

import 'package:appdiscovery_sdk/appdiscovery_sdk.dart';
import 'package:appdiscovery_sdk/src/platform/app_discovery_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlatform extends AppDiscoveryPlatform {
  final List<Map<String, Object?>> calls = [];
  final StreamController<AppDiscoveryReward> rewards = StreamController.broadcast();
  final StreamController<void> closes = StreamController.broadcast();
  bool showResult = true;
  List<AppDiscoveryReward> pending = const [];

  @override
  Future<bool> initSDK({
    required String host,
    required String appId,
    required String sdkKey,
    String? playerId,
    String? trackerHost,
  }) async {
    calls.add({
      'call': 'initSDK',
      'host': host,
      'trackerHost': trackerHost,
      'appId': appId,
      'sdkKey': sdkKey,
      'playerId': playerId,
    });
    return true;
  }

  @override
  Future<bool> setUserId(String playerId) async {
    calls.add({'call': 'setUserId', 'playerId': playerId});
    return true;
  }

  @override
  Future<bool> showOfferwall({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) async {
    calls.add({
      'call': 'showOfferwall',
      'host': host,
      'trackerHost': trackerHost,
      'appId': appId,
      'sdkKey': sdkKey,
      'playerId': playerId,
    });
    return showResult;
  }

  @override
  Future<List<AppDiscoveryReward>> syncPendingRewards({
    required String host,
    required String appId,
    required String sdkKey,
    required String playerId,
    String? trackerHost,
  }) async {
    calls.add({
      'call': 'syncPendingRewards',
      'host': host,
      'trackerHost': trackerHost,
      'playerId': playerId,
    });
    return pending;
  }

  @override
  Stream<AppDiscoveryReward> get onRewardStream => rewards.stream;

  @override
  Stream<void> get onCloseStream => closes.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePlatform platform;

  setUp(() {
    platform = FakePlatform();
    AppDiscoveryPlatform.instance = platform;
    AppDiscovery.resetForTesting();
  });

  group('AppDiscoveryReward', () {
    test('fromMap parses the typed fields and keeps the raw payload', () {
      final reward = AppDiscoveryReward.fromMap({
        'amount': 150.5,
        'txid': 'tx_12345',
        'status': 'approved',
        'publisher_id': 99,
        'player_id': 'user_test',
        'timestamp': 1700000000,
        'type': 'coins',
        'click_id': 'c1',
      });

      expect(reward.amount, 150.5);
      expect(reward.txid, 'tx_12345');
      expect(reward.status, 'approved');
      expect(reward.publisherId, 99);
      expect(reward.playerId, 'user_test');
      expect(reward.timestamp, 1700000000);
      expect(reward.type, 'coins');
      expect(reward['click_id'], 'c1');
    });

    test('fromMap tolerates strings, alternative keys and missing values', () {
      final reward = AppDiscoveryReward.fromMap({
        'payout': '12.5',
        'tx_id': 'abc',
        'publisherId': '7',
      });
      expect(reward.amount, 12.5);
      expect(reward.txid, 'abc');
      expect(reward.status, 'approved');
      expect(reward.publisherId, 7);
      expect(reward.playerId, isNull);
    });
  });

  group('AppDiscovery.init', () {
    test('requires a host: there is no default', () async {
      await expectLater(
        AppDiscovery.init(host: '', appId: 'a', sdkKey: 'k'),
        throwsArgumentError,
      );
      expect(platform.calls, isEmpty);
      expect(AppDiscovery.isInitialized(), isFalse);
    });

    test('rejects an invalid host and an invalid tracker host', () async {
      await expectLater(
        AppDiscovery.init(host: 'http://offers.example.com', appId: 'a', sdkKey: 'k'),
        throwsArgumentError,
      );
      await expectLater(
        AppDiscovery.init(
            host: 'offers.example.com', trackerHost: 'a b', appId: 'a', sdkKey: 'k'),
        throwsArgumentError,
      );
      expect(platform.calls, isEmpty);
    });

    test('stores the configuration and hands the normalised host to the platform', () async {
      final ok = await AppDiscovery.init(
        host: 'HTTPS://Offers.Example.com/',
        trackerHost: 'track.example.com',
        appId: ' app1 ',
        sdkKey: 'key1',
        playerId: 'player1',
      );

      expect(ok, isTrue);
      expect(AppDiscovery.getHost(), 'offers.example.com');
      expect(AppDiscovery.getTrackerHost(), 'track.example.com');
      expect(AppDiscovery.getAppId(), 'app1');
      expect(AppDiscovery.getSdkKey(), 'key1');
      expect(AppDiscovery.getPlayerId(), 'player1');
      expect(AppDiscovery.isInitialized(), isTrue);
      expect(platform.calls.single['host'], 'offers.example.com');
      expect(platform.calls.single['trackerHost'], 'track.example.com');
    });

    test('initFromConfig forwards every field', () async {
      await AppDiscovery.initFromConfig(const AppDiscoveryConfig(
        host: 'offers.example.com',
        appId: 'a',
        sdkKey: 'k',
        playerId: 'p',
      ));
      expect(platform.calls.single['call'], 'initSDK');
      expect(platform.calls.single['playerId'], 'p');
      expect(platform.calls.single['trackerHost'], isNull);
    });
  });

  group('AppDiscovery.setUserId', () {
    test('updates the player id and calls the platform', () async {
      await AppDiscovery.setUserId('new_player_456');
      expect(AppDiscovery.getPlayerId(), 'new_player_456');
      expect(platform.calls.single, {'call': 'setUserId', 'playerId': 'new_player_456'});
    });
  });

  group('AppDiscovery.showOfferwall', () {
    test('uses the values from init', () async {
      await AppDiscovery.init(
          host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p');
      platform.calls.clear();

      expect(await AppDiscovery.showOfferwall(), isTrue);
      expect(platform.calls.single, {
        'call': 'showOfferwall',
        'host': 'offers.example.com',
        'trackerHost': null,
        'appId': 'a',
        'sdkKey': 'k',
        'playerId': 'p',
      });
    });

    test('per-call values override the stored ones', () async {
      await AppDiscovery.init(
          host: 'offers.example.com',
          trackerHost: 'track.example.com',
          appId: 'a',
          sdkKey: 'k',
          playerId: 'p');
      platform.calls.clear();

      await AppDiscovery.showOfferwallWithOptions(const AppDiscoveryOfferwallOptions(
        host: 'other.example.com',
        playerId: 'p2',
      ));
      final call = platform.calls.single;
      expect(call['host'], 'other.example.com');
      // A different host does not inherit the stored tracker host.
      expect(call['trackerHost'], isNull);
      expect(call['playerId'], 'p2');
      expect(call['appId'], 'a');
    });

    test('throws instead of guessing a host when none is configured', () async {
      await expectLater(
        AppDiscovery.showOfferwall(appId: 'a', sdkKey: 'k', playerId: 'p'),
        throwsArgumentError,
      );
      expect(platform.calls, isEmpty);
    });

    test('returns false without appId or sdkKey', () async {
      expect(
        await AppDiscovery.showOfferwall(host: 'offers.example.com', playerId: 'p'),
        isFalse,
      );
      expect(platform.calls, isEmpty);
    });

    test('passes the platform result through', () async {
      platform.showResult = false;
      expect(
        await AppDiscovery.showOfferwall(
            host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p'),
        isFalse,
      );
    });
  });

  group('AppDiscovery.syncPendingRewards', () {
    test('returns what the platform found', () async {
      platform.pending = [
        const AppDiscoveryReward(amount: 5, txid: 't1', status: 'approved')
      ];
      final rewards = await AppDiscovery.syncPendingRewards(
          host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p');
      expect(rewards.single.txid, 't1');
      expect(platform.calls.single['call'], 'syncPendingRewards');
    });

    test('needs a player id', () async {
      final rewards = await AppDiscovery.syncPendingRewards(
          host: 'offers.example.com', appId: 'a', sdkKey: 'k');
      expect(rewards, isEmpty);
      expect(platform.calls, isEmpty);
    });
  });

  group('OfferwallInstance', () {
    test('create validates the host and keeps the configuration', () {
      expect(
        () => AppDiscovery.create(host: '', appId: 'a', sdkKey: 'k', playerId: 'p'),
        throwsArgumentError,
      );

      final offerwall = AppDiscovery.create(
        host: 'Offers.Example.com',
        trackerHost: 'track.example.com',
        appId: 'app1',
        sdkKey: 'key1',
        playerId: 'user1',
      );
      expect(offerwall.host, 'offers.example.com');
      expect(offerwall.trackerHost, 'track.example.com');
      expect(offerwall.appId, 'app1');
      expect(offerwall.sdkKey, 'key1');
      expect(offerwall.playerId, 'user1');
      expect(offerwall.getConfig().host, 'offers.example.com');
    });

    test('show passes its own configuration to the platform', () async {
      final offerwall = AppDiscovery.create(
          host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p');
      expect(await offerwall.show(), isTrue);
      expect(platform.calls.single['host'], 'offers.example.com');
      expect(platform.calls.single['playerId'], 'p');
    });

    test('delivers rewards, and stops after the offerwall closed', () async {
      final received = <String>[];
      var closed = 0;
      final offerwall = AppDiscovery.create(
          host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p')
        ..onReward = ((r) => received.add(r.txid))
        ..onClose = (() => closed++);

      await offerwall.show();
      platform.rewards.add(const AppDiscoveryReward(amount: 1, txid: 'a', status: 'approved'));
      await Future<void>.delayed(Duration.zero);
      platform.closes.add(null);
      await Future<void>.delayed(Duration.zero);
      platform.rewards.add(const AppDiscoveryReward(amount: 1, txid: 'b', status: 'approved'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['a']);
      expect(closed, 1);
    });
  });

  group('events', () {
    test('onReward and onClose subscriptions can be cancelled in bulk', () async {
      final received = <String>[];
      AppDiscovery.onReward((r) => received.add(r.txid));
      platform.rewards.add(const AppDiscoveryReward(amount: 1, txid: 'x', status: 'approved'));
      await Future<void>.delayed(Duration.zero);
      AppDiscovery.removeAllListeners();
      platform.rewards.add(const AppDiscoveryReward(amount: 1, txid: 'y', status: 'approved'));
      await Future<void>.delayed(Duration.zero);
      expect(received, ['x']);
    });
  });
}
