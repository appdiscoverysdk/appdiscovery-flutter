import 'package:appdiscovery_sdk/appdiscovery_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeHost', () {
    test('accepts a plain host and lower-cases it', () {
      expect(normalizeHost('Offers.Example.com'), 'offers.example.com');
    });

    test('accepts an https URL and trailing slashes', () {
      expect(normalizeHost('https://offers.example.com/'), 'offers.example.com');
      expect(normalizeHost('HTTPS://offers.example.com//'), 'offers.example.com');
    });

    test('accepts a port', () {
      expect(normalizeHost('offers.example.com:8443'), 'offers.example.com:8443');
    });

    test('trims whitespace around the value', () {
      expect(normalizeHost('  offers.example.com  '), 'offers.example.com');
    });

    test('rejects blank and null values', () {
      expect(() => normalizeHost(null), throwsArgumentError);
      expect(() => normalizeHost(''), throwsArgumentError);
      expect(() => normalizeHost('   '), throwsArgumentError);
    });

    test('rejects cleartext http and other schemes', () {
      expect(() => normalizeHost('http://offers.example.com'), throwsArgumentError);
      expect(() => normalizeHost('ftp://offers.example.com'), throwsArgumentError);
    });

    test('rejects paths, queries and embedded whitespace', () {
      expect(() => normalizeHost('offers.example.com/path'), throwsArgumentError);
      expect(() => normalizeHost('offers.example.com?x=1'), throwsArgumentError);
      expect(() => normalizeHost('offers example.com'), throwsArgumentError);
      expect(() => normalizeHost('-offers.example.com'), throwsArgumentError);
    });

    test('names the setting in the error', () {
      expect(
        () => normalizeHost('', setting: 'trackerHost'),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'trackerHost')),
      );
    });
  });
}
