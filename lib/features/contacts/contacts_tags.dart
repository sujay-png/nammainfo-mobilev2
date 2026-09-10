import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local, per-device tag/folder assignments for saved connections
/// (Client / Prospect / Vendor / Partner, or a custom folder). Kept
/// client-side for now — move to a Supabase table if you want tags to
/// sync across devices.
class ContactsTagsStore {
  static const _prefsKey = 'namma_contact_tags';
  static const defaultFolders = ['Client', 'Prospect', 'Vendor', 'Partner'];

  Future<Map<String, String>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _writeAll(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<String?> tagFor(String connectionId) async => (await _readAll())[connectionId];

  Future<void> setTag(String connectionId, String? folder) async {
    final all = await _readAll();
    if (folder == null) {
      all.remove(connectionId);
    } else {
      all[connectionId] = folder;
    }
    await _writeAll(all);
  }

  Future<List<String>> customFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('namma_custom_folders') ?? [];
  }

  Future<void> addCustomFolder(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('namma_custom_folders') ?? [];
    if (!list.contains(name)) {
      list.add(name);
      await prefs.setStringList('namma_custom_folders', list);
    }
  }
}
