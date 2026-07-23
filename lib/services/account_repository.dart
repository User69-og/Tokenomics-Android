import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_profile.dart';

class AccountRepository {
  static const String _accountsKey = 'accounts_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Account CRUD ──────────────────────────────────────────────────────────

  Future<List<AccountProfile>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AccountProfile.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> saveAccounts(List<AccountProfile> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsKey, json);
  }

  Future<void> addAccount(AccountProfile account) async {
    final accounts = await loadAccounts();
    final updated = AccountProfile(
      id: account.id,
      label: account.label,
      providerId: account.providerId,
      isEnabled: account.isEnabled,
      sortOrder: accounts.length,
      createdAt: account.createdAt,
    );
    accounts.add(updated);
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(AccountProfile account) async {
    final accounts = await loadAccounts();
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      accounts[idx] = account;
      await saveAccounts(accounts);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);
    // Also delete the credential
    await _secureStorage.delete(key: _credentialKey(accountId));
  }

  // ── Credential Storage (Android Keystore) ─────────────────────────────────

  String _credentialKey(String accountId) => 'credential_$accountId';

  Future<void> saveCredential(String accountId, String credential) async {
    await _secureStorage.write(
      key: _credentialKey(accountId),
      value: credential,
    );
  }

  Future<String?> loadCredential(String accountId) async {
    return await _secureStorage.read(key: _credentialKey(accountId));
  }

  Future<bool> hasCredential(String accountId) async {
    final val = await _secureStorage.read(key: _credentialKey(accountId));
    return val != null && val.isNotEmpty;
  }

  Future<List<AccountProfile>> accountsForProvider(String providerId) async {
    final all = await loadAccounts();
    return all.where((a) => a.providerId == providerId).toList();
  }
}
