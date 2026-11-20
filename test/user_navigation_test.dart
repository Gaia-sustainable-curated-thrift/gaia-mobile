import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gaia_mobile/models/user_profile.dart';
import 'package:gaia_mobile/pages/account_page.dart';
import 'package:gaia_mobile/pages/user/account_forms.dart';
import 'package:gaia_mobile/services/user_api.dart';
import 'package:gaia_mobile/services/user_session.dart';

const profile = <String, dynamic>{
  'id': 1,
  'full_name': 'Gaia Buyer',
  'username': 'buyer',
  'email': 'buyer@example.com',
  'phone': '+628123456789',
  'city': 'Depok',
  'country': 'Indonesia',
  'email_verified': false,
  'has_password': true,
  'avatar_url': null,
};

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<UserSession> openAccount(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler, {
  bool signedIn = false,
}) async {
  final session = UserSession(
    api: UserApi(
      client: MockClient(handler),
      baseUrl: 'https://gaia.test/api/accounts/',
    ),
  );
  if (signedIn) {
    session.user = const UserProfile(profile);
    session.api.token = 'test-token';
  }
  addTearDown(session.dispose);
  await tester.pumpWidget(
    UserScope(
      session: session,
      child: const MaterialApp(home: Scaffold(body: AccountPage())),
    ),
  );
  return session;
}

Future<void> tapText(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  final target = button.evaluate().isNotEmpty ? button : find.text(label).last;
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String label, String value) async {
  final target = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.enterText(target, value);
}

void main() {
  testWidgets(
    'login validates input, reports server errors, and opens real account',
    (tester) async {
      var calls = 0;
      final session = await openAccount(tester, (request) async {
        expect(request.url.path, '/api/accounts/login/');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body)['username'], 'buyer@example.com');
        calls++;
        if (calls == 1) {
          return jsonResponse({
            '__all__': ['Invalid credentials.'],
          }, 400);
        }
        return jsonResponse({'token': 'valid-token', 'user': profile});
      });
      await tapText(tester, 'Masuk');
      await tapText(tester, 'Masuk');
      expect(calls, 0);
      await fill(tester, 'Email atau username', 'buyer@example.com');
      await fill(tester, 'Password', 'StrongPass!8462');
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
        isTrue,
      );
      await tapText(tester, 'Masuk');
      expect(find.text('Invalid credentials.'), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
      await tapText(tester, 'Masuk');
      expect(session.api.token, 'valid-token');
      expect(find.text('Halo, Gaia Buyer'), findsOneWidget);
      expect(find.text('Profil saya'), findsOneWidget);
    },
  );

  testWidgets('registration confirms password and submits web field names', (
    tester,
  ) async {
    var calls = 0;
    await openAccount(tester, (request) async {
      calls++;
      expect(request.url.path, '/api/accounts/register/');
      final data = jsonDecode(request.body);
      expect(data['full_name'], 'New Buyer');
      expect(data['password1'], data['password2']);
      return jsonResponse({
        'token': 'registered',
        'user': profile,
        'warning': null,
      }, 201);
    });
    await tapText(tester, 'Buat akun');
    await fill(tester, 'Nama lengkap', 'New Buyer');
    await fill(tester, 'Email', 'new@example.com');
    await fill(tester, 'Password', 'StrongPass!8462');
    await fill(tester, 'Konfirmasi password', 'wrong');
    await tapText(tester, 'Daftar');
    expect(calls, 0);
    await fill(tester, 'Konfirmasi password', 'StrongPass!8462');
    await tapText(tester, 'Daftar');
    expect(calls, 1);
    expect(find.text('Halo, Gaia Buyer'), findsOneWidget);
  });

  testWidgets(
    'small phone edits profile with keyboard and preserves immutable email',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      var saved = false;
      final session = await openAccount(tester, (request) async {
        expect(request.headers['Authorization'], 'Token test-token');
        if (request.method == 'PATCH') {
          final data = jsonDecode(request.body) as Map<String, dynamic>;
          expect(data.containsKey('email'), isFalse);
          saved = true;
          return jsonResponse({...profile, ...data});
        }
        return jsonResponse(profile);
      }, signedIn: true);
      await tapText(tester, 'Profil saya');
      expect(find.text('buyer@example.com'), findsOneWidget);
      await tapText(tester, 'Edit profil');
      await fill(tester, 'Nama lengkap', 'Updated Buyer');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await tapText(tester, 'Simpan perubahan');
      expect(saved, isTrue);
      expect(session.user!.displayName, 'Updated Buyer');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wishlist displays server rows, removes and restores own item', (
    tester,
  ) async {
    var removed = false;
    await openAccount(tester, (request) async {
      expect(request.headers['Authorization'], 'Token test-token');
      if (request.method == 'DELETE') {
        expect(request.url.path, '/api/accounts/wishlist/7/');
        removed = true;
        return http.Response('', 204);
      }
      if (request.method == 'POST') {
        expect(request.url.path, '/api/accounts/wishlist/7/restore/');
        removed = false;
        return jsonResponse({'id': 7});
      }
      return jsonResponse({
        'count': removed ? 0 : 1,
        'next': null,
        'previous': null,
        'results': removed
            ? []
            : [
                {
                  'id': 7,
                  'title': 'Vintage Jacket',
                  'price': 125000,
                  'condition': 'Good',
                },
              ],
      });
    }, signedIn: true);
    await tapText(tester, 'Wishlist');
    expect(find.text('Vintage Jacket'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus Vintage Jacket'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
    expect(find.text('Vintage Jacket'), findsNothing);
    await tapText(tester, 'Urungkan penghapusan terakhir');
    expect(removed, isFalse);
    expect(find.text('Vintage Jacket'), findsOneWidget);
  });

  testWidgets('logout requires confirmation and clears account', (
    tester,
  ) async {
    final session = await openAccount(tester, (request) async {
      expect(request.url.path, '/api/accounts/logout/');
      return http.Response('', 204);
    }, signedIn: true);
    await tapText(tester, 'Pengaturan akun');
    await tapText(tester, 'Keluar');
    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(session.user, isNull);
    expect(session.api.token, isNull);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
