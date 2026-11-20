import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gaia_mobile/models/user_profile.dart';
import 'package:gaia_mobile/services/user_api.dart';
import 'package:gaia_mobile/services/user_session.dart';

void main() {
  test('late profile response cannot restore a logged-out session', () async {
    final response = Completer<http.Response>();
    final session = UserSession(
      api: UserApi(client: MockClient((_) => response.future)),
    );
    addTearDown(session.dispose);
    session.api.token = 'old-token';
    session.user = const UserProfile({'username': 'buyer'});
    final pending = session.refreshProfile();
    session.clear();
    response.complete(http.Response('{"username":"buyer"}', 200));
    await pending;
    expect(session.user, isNull);
    expect(session.api.token, isNull);
  });
  test('API uses JSON, token, HTTP method and configured backend', () async {
    final api = UserApi(
      baseUrl: 'https://gaia.test/api/accounts/',
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://gaia.test/api/accounts/me/');
        expect(request.method, 'PATCH');
        expect(request.headers['Authorization'], 'Token private-token');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {'city': 'Depok'});
        return http.Response.bytes(
          utf8.encode(jsonEncode({'full_name': 'Pembeli Gaia'})),
          200,
        );
      }),
    );
    addTearDown(api.close);
    api.token = 'private-token';
    expect(
      (await api.request('PATCH', 'me/', {'city': 'Depok'}))['full_name'],
      'Pembeli Gaia',
    );
  });

  test('401 clears revoked session and reports server error', () async {
    final api = UserApi(
      client: MockClient(
        (_) async => http.Response('{"detail":"Invalid token."}', 401),
      ),
    );
    final session = UserSession(api: api);
    addTearDown(session.dispose);
    session.user = const UserProfile({'username': 'buyer'});
    api.token = 'revoked';
    await expectLater(
      session.refreshProfile(),
      throwsA(isA<UserApiException>()),
    );
    expect(session.user, isNull);
    expect(api.token, isNull);
  });

  test(
    'HTML from an undeployed endpoint becomes a useful connection error',
    () async {
      final api = UserApi(
        client: MockClient(
          (_) async => http.Response('<html>Not found</html>', 404),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        api.request('POST', 'login/', {}),
        throwsA(
          isA<UserApiException>().having(
            (e) => e.message,
            'message',
            contains('API User belum tersedia'),
          ),
        ),
      );
    },
  );

  test('network errors do not expose a fake logged-in account', () async {
    final session = UserSession(
      api: UserApi(
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
    );
    addTearDown(session.dispose);
    await expectLater(
      session.authenticate('login', {
        'username': 'buyer',
        'password': 'invalid',
      }),
      throwsA(isA<UserApiException>()),
    );
    expect(session.user, isNull);
    expect(session.api.token, isNull);
  });
}
