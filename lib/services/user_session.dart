import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'user_api.dart';

class UserSession extends ChangeNotifier {
  UserSession({UserApi? api}) : api = api ?? UserApi() {
    this.api.onUnauthorized = clear;
  }

  final UserApi api;
  UserProfile? user;
  int _generation = 0;

  Future<String?> authenticate(
    String action,
    Map<String, dynamic> fields,
  ) async {
    final generation = ++_generation;
    final response = await api.request('POST', '$action/', fields);
    if (generation != _generation) return null;
    api.token = response['token'] as String;
    user = UserProfile(response['user'] as Map<String, dynamic>);
    notifyListeners();
    return response['warning'] as String?;
  }

  Future<void> refreshProfile() async {
    final generation = _generation;
    final response = await api.request('GET', 'me/');
    if (generation != _generation) return;
    user = UserProfile(response);
    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> fields) async {
    final generation = _generation;
    final response = await api.request('PATCH', 'me/', fields);
    if (generation != _generation) return;
    user = UserProfile(response);
    notifyListeners();
  }

  Future<void> logout() async {
    final generation = ++_generation;
    await api.request('POST', 'logout/');
    if (generation == _generation) clear();
  }

  void clear() {
    _generation++;
    api.token = null;
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    api.onUnauthorized = null;
    api.close();
    super.dispose();
  }
}

class UserScope extends InheritedNotifier<UserSession> {
  const UserScope({
    super.key,
    required UserSession session,
    required super.child,
  }) : super(notifier: session);

  static UserSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserScope>()!.notifier!;

  static UserSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserScope>()?.notifier;
}
