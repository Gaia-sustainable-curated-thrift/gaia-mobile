// Run against an isolated local Django database, never the production site.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gaia_mobile/services/user_api.dart';

Future<void> main(List<String> args) async {
  final base = args.isEmpty
      ? 'http://127.0.0.1:8897/api/accounts/'
      : args.single;
  if (!['localhost', '127.0.0.1'].contains(Uri.parse(base).host)) {
    throw ArgumentError('Use an isolated local backend for this smoke test.');
  }
  final api = UserApi(baseUrl: base);
  final random = Random.secure();
  final password =
      'Gaia!${base64UrlEncode(List.generate(24, (_) => random.nextInt(256)))}';
  final email =
      'mobile-smoke-${DateTime.now().microsecondsSinceEpoch}@example.invalid';
  var created = false;
  try {
    final registration = await api.request('POST', 'register/', {
      'full_name': 'Mobile Smoke',
      'email': email,
      'password1': password,
      'password2': password,
    });
    created = true;
    api.token = registration['token'] as String;
    await api.request('PATCH', 'me/', {
      'full_name': 'Mobile Smoke Updated',
      'phone': '+628123456789',
      'city': 'Depok',
      'country': 'Indonesia',
    });
    final profile = await api.request('GET', 'me/');
    if (profile['full_name'] != 'Mobile Smoke Updated' ||
        profile['email'] != email) {
      throw StateError('Profile did not persist in Django.');
    }
    final wishlist = await api.request('GET', 'wishlist/');
    if (wishlist['count'] != 0) {
      throw StateError('Unexpected new account wishlist.');
    }
    await api.request('POST', 'logout/');
    try {
      await api.request('GET', 'me/');
      throw StateError('Logged-out token still works.');
    } on UserApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }
    api.token = null;
    final login = await api.request('POST', 'login/', {
      'username': email,
      'password': password,
    });
    api.token = login['token'] as String;
    stdout.writeln(
      'PASS: Dart HTTP -> Django register, update/read profile, wishlist, logout, rejected token, login.',
    );
  } finally {
    if (created) {
      // A fresh login also permits cleanup if a preceding logout already ran.
      api.token = null;
      final login = await api.request('POST', 'login/', {
        'username': email,
        'password': password,
      });
      api.token = login['token'] as String;
      await api.request('DELETE', 'me/', {
        'password': password,
        'confirmation': 'DELETE',
        'acknowledge': true,
      });
      stdout.writeln('PASS: temporary account deleted.');
    }
    api.close();
  }
}
