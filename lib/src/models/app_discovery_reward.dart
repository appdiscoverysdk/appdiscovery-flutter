/// A reward event received from the offerwall.
class AppDiscoveryReward {
  /// The amount of currency / points rewarded.
  final double amount;

  /// The unique transaction identifier. Use it to avoid crediting twice.
  final String txid;

  /// The status of the reward transaction (for example `approved`).
  final String status;

  /// The publisher ID associated with the transaction.
  final int? publisherId;

  /// The player who earned the reward.
  final String? playerId;

  /// Unix timestamp when the reward was issued.
  final int? timestamp;

  /// The optional reward type or currency name.
  final String? type;

  /// The complete payload as received from the native SDK. Parameters sent by
  /// the server that this class has no field for are available here.
  final Map<String, dynamic> raw;

  const AppDiscoveryReward({
    required this.amount,
    required this.txid,
    required this.status,
    this.publisherId,
    this.playerId,
    this.timestamp,
    this.type,
    this.raw = const {},
  });

  /// Builds a reward from the map the platform channel delivers.
  factory AppDiscoveryReward.fromMap(Map<dynamic, dynamic> map) {
    double parseAmount(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int? parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return AppDiscoveryReward(
      amount: parseAmount(map['amount'] ?? map['payout']),
      txid: (map['txid'] ?? map['tx_id'] ?? '').toString(),
      status: (map['status'] ?? 'approved').toString(),
      publisherId: parseInt(map['publisher_id'] ?? map['publisherId']),
      playerId: (map['player_id'] ?? map['playerId'])?.toString(),
      timestamp: parseInt(map['timestamp']),
      type: map['type']?.toString(),
      raw: Map<String, dynamic>.from(map),
    );
  }

  /// Reads any parameter of the payload (for example `click_id` or `sub1`).
  dynamic operator [](String key) => raw[key];

  /// The typed fields as a plain map.
  Map<String, dynamic> toMap() => {
        'amount': amount,
        'txid': txid,
        'status': status,
        'publisher_id': publisherId,
        'player_id': playerId,
        'timestamp': timestamp,
        'type': type,
      };

  @override
  String toString() {
    return 'AppDiscoveryReward(amount: $amount, txid: $txid, status: $status, '
        'playerId: $playerId, timestamp: $timestamp, type: $type)';
  }
}
