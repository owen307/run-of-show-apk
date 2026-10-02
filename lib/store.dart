import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract class ShowStore {
  Future<Persisted?> load();
  Future<void> save(Persisted data);
}

class MemoryStore implements ShowStore {
  Persisted? value;

  @override
  Future<Persisted?> load() async => value;

  @override
  Future<void> save(Persisted data) async {
    value = data;
  }
}

class PrefsStore implements ShowStore {
  static const key = 'run_of_show.v1';

  @override
  Future<Persisted?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Persisted.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> save(Persisted data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data.toJson()));
  }
}
