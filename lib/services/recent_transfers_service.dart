import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'bank_logo_mapper.dart';

class RecentTransfersService {
  static const String _key = 'recent_transfers';
  static const int maxEntries = 10;

  // Load list from SharedPreferences
  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map((e) => Map<String, String>.from(jsonDecode(e) as Map))
        .toList();
  }

  // Add new entry (no duplicates, max 10, newest on top)
  // Only adds if it's a bank transfer (not QR or Telebirr)
  static Future<void> add({
    required String accountName,
    required String bankName,
    required String accountNumber,
    bool isFromQr = false,
    bool isTelebirrTransfer = false,
  }) async {
    // Skip adding if it's QR or Telebirr transfer
    if (isFromQr || isTelebirrTransfer) {
      return; // Don't add to recent transfers
    }
    
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, String>> entries = await load();

    // Remove duplicate based on accountNumber + bankName
    entries.removeWhere((e) =>
        e['accountNumber'] == accountNumber && e['bankName'] == bankName);

    // Add new entry at top
    final newEntry = {
      'accountName': accountName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'bankLogo': BankLogoMapper.getLogo(bankName),
    };
    entries.insert(0, newEntry);

    // Trim to max 10
    if (entries.length > maxEntries) {
      entries = entries.sublist(0, maxEntries);
    }

    // Save
    final List<String> encoded = entries.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_key, encoded);
  }

  // Optional: clear all (for trash icon)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
