final RegExp _hostPattern =
    RegExp(r'^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]{1,5})?$');

/// Validates and normalises a host setting to a bare, lower-case
/// `hostname[:port]`.
///
/// Accepts `offers.example.com` or `https://offers.example.com/`. Rejects blank
/// values, other schemes (cleartext `http` included), paths, queries and
/// whitespace. The native SDKs apply the same rules; checking here makes a
/// wrong host fail at the call site instead of inside a platform channel.
///
/// Throws an [ArgumentError] naming [setting] when the value is not usable.
String normalizeHost(String? raw, {String setting = 'host'}) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(raw, setting, '$setting is required');
  }

  String withoutScheme;
  if (trimmed.toLowerCase().startsWith('https://')) {
    withoutScheme = trimmed.substring('https://'.length);
  } else if (trimmed.contains('://')) {
    throw ArgumentError.value(
        raw, setting, '$setting must be a host name or an https:// URL');
  } else {
    withoutScheme = trimmed;
  }
  withoutScheme = withoutScheme.replaceAll(RegExp(r'/+$'), '');

  if (!_hostPattern.hasMatch(withoutScheme)) {
    throw ArgumentError.value(
        raw, setting, '$setting must be a plain host name such as example.com');
  }
  return withoutScheme.toLowerCase();
}
