import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  static const _key = 'hostel_session';

  UserSession? session;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      session = null;
      return;
    }
    session = UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(UserSession value) async {
    session = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(value.toJson()));
  }

  Future<void> clear() async {
    session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
