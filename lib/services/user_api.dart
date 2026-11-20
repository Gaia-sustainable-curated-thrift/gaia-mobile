import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class UserApiException implements Exception {
  const UserApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Same Django users and account data as Gaia web. Tokens stay in memory only.
class UserApi {
  UserApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _base = Uri.parse(baseUrl ?? endpoint);

  static const endpoint = String.fromEnvironment(
    'GAIA_USER_API_BASE_URL',
    defaultValue: 'https://danar-iqbal-gaia.pws.cs.ui.ac.id/api/accounts/',
  );
  final http.Client _client;
  final Uri _base;
  String? token;
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final request = http.Request(method, _base.resolve(path));
    final requestToken = token;
    request.followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Token $token';
    if (data != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(data);
    }
    try {
      final response = await (() async {
        return http.Response.fromStream(await _client.send(request));
      })().timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 &&
          requestToken != null &&
          token == requestToken) {
        onUnauthorized?.call();
      }
      dynamic body;
      try {
        body = response.bodyBytes.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const UserApiException(
          'API User belum tersedia atau server tidak mengirim JSON. Coba lagi nanti.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = body is Map
            ? body.entries
                  .map((entry) {
                    final value = entry.value;
                    final text = value is List ? value.join(' ') : '$value';
                    return entry.key == 'detail' || entry.key == '__all__'
                        ? text
                        : '${entry.key}: $text';
                  })
                  .join('\n')
            : 'Permintaan gagal (${response.statusCode}).';
        throw UserApiException(message, response.statusCode);
      }
      if (body is! Map<String, dynamic>) {
        throw const UserApiException('Format respons akun tidak sesuai.');
      }
      return body;
    } on TimeoutException {
      throw const UserApiException(
        'Server terlalu lama merespons. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const UserApiException(
        'Tidak dapat terhubung ke Gaia. Periksa koneksi internet.',
      );
    }
  }

  void close() => _client.close();
}
