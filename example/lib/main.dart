import 'dart:async';

import 'package:appdiscovery_sdk/appdiscovery_sdk.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: OfferwallPage());
  }
}

class OfferwallPage extends StatefulWidget {
  const OfferwallPage({super.key});

  @override
  State<OfferwallPage> createState() => _OfferwallPageState();
}

class _OfferwallPageState extends State<OfferwallPage> {
  // Replace with the values from your dashboard. The host is required:
  // it is the host of YOUR offerwall, there is no default.
  final _host = TextEditingController(text: 'offers.example.com');
  final _appId = TextEditingController(text: 'YOUR_APP_ID');
  final _sdkKey = TextEditingController(text: 'YOUR_SDK_KEY');
  final _playerId = TextEditingController(text: 'player_123');

  final List<String> _log = [];
  StreamSubscription<AppDiscoveryReward>? _rewardSub;
  StreamSubscription<void>? _closeSub;

  @override
  void initState() {
    super.initState();
    _rewardSub = AppDiscovery.onReward((reward) {
      _add('Reward: ${reward.amount} (txid ${reward.txid}, ${reward.status})');
    });
    _closeSub = AppDiscovery.onClose(() => _add('Offerwall closed'));
  }

  @override
  void dispose() {
    _rewardSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  void _add(String line) => setState(() => _log.insert(0, line));

  Future<void> _show() async {
    try {
      await AppDiscovery.init(
        host: _host.text,
        appId: _appId.text,
        sdkKey: _sdkKey.text,
        playerId: _playerId.text,
      );
      final shown = await AppDiscovery.showOfferwall();
      _add(shown ? 'Offerwall shown' : 'Offerwall could not be shown');
    } on ArgumentError catch (e) {
      _add('Invalid setting: ${e.message}');
    }
  }

  Future<void> _sync() async {
    final rewards = await AppDiscovery.syncPendingRewards();
    _add('Pending rewards: ${rewards.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AppDiscovery example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _host, decoration: const InputDecoration(labelText: 'Host')),
            TextField(controller: _appId, decoration: const InputDecoration(labelText: 'App ID')),
            TextField(controller: _sdkKey, decoration: const InputDecoration(labelText: 'SDK key')),
            TextField(controller: _playerId, decoration: const InputDecoration(labelText: 'Player ID')),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(onPressed: _show, child: const Text('Show offerwall')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: _sync, child: const Text('Sync pending rewards')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(children: [for (final line in _log) Text(line)]),
            ),
          ],
        ),
      ),
    );
  }
}
