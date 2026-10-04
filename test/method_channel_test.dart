import 'package:appdiscovery_sdk/appdiscovery_sdk.dart';
import 'package:appdiscovery_sdk/src/platform/app_discovery_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late MethodChannelAppDiscovery platform;
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) handler = (_) => true;

  setUp(() {
    platform = MethodChannelAppDiscovery();
    calls.clear();
    handler = (_) => true;
    messenger.setMockMethodCallHandler(platform.methodChannel, (MethodCall call) async {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(platform.methodChannel, null);
    messenger.setMockStreamHandler(platform.eventChannel, null);
  });

  test('uses neutral channel names', () {
    expect(platform.methodChannel.name, 'com.appdiscoverysdk.flutter/methods');
    expect(platform.eventChannel.name, 'com.appdiscoverysdk.flutter/events');
  });

  test('initSDK sends the host and the credentials', () async {
    final ok = await platform.initSDK(
      host: 'offers.example.com',
      trackerHost: 'track.example.com',
      appId: 'a',
      sdkKey: 'k',
      playerId: 'p',
    );
    expect(ok, isTrue);
    expect(calls.single.method, 'initSDK');
    expect(calls.single.arguments, {
      'host': 'offers.example.com',
      'trackerHost': 'track.example.com',
      'appId': 'a',
      'sdkKey': 'k',
      'playerId': 'p',
    });
  });

  test('showOfferwall sends the host and returns the native result', () async {
    handler = (_) => false;
    final ok = await platform.showOfferwall(
        host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p');
    expect(ok, isFalse);
    expect(calls.single.method, 'showOfferwall');
    expect((calls.single.arguments as Map)['host'], 'offers.example.com');
  });

  test('a native error becomes false, not an exception', () async {
    handler = (_) => throw PlatformException(code: 'INVALID_HOST', message: 'host is required');
    final ok = await platform.showOfferwall(
        host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p');
    expect(ok, isFalse);
  });

  test('syncPendingRewards parses the native list', () async {
    handler = (call) => [
          {'amount': 3.5, 'txid': 't1', 'status': 'approved'},
          {'amount': 1, 'txid': 't2', 'status': 'pending'},
        ];
    final rewards = await platform.syncPendingRewards(
        host: 'offers.example.com', appId: 'a', sdkKey: 'k', playerId: 'p');
    expect(rewards.map((r) => r.txid), ['t1', 't2']);
    expect(rewards.first.amount, 3.5);
  });

  test('reward and close events arrive exactly once on the matching stream', () async {
    messenger.setMockStreamHandler(
      platform.eventChannel,
      MockStreamHandler.inline(onListen: (arguments, events) {
        events.success({
          'event': 'onReward',
          'data': {'amount': 2, 'txid': 'tx1', 'status': 'approved'},
        });
        events.success({'event': 'onClose'});
      }),
    );

    final rewards = <AppDiscoveryReward>[];
    var closes = 0;
    platform.onRewardStream.listen(rewards.add);
    platform.onCloseStream.listen((_) => closes++);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(rewards.map((r) => r.txid), ['tx1']);
    expect(closes, 1);
  });
}
