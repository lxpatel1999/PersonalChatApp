import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kEndpoint = 'endpoint';
  static const _kApiKey = 'apiKey';
  static const _kAuthHeaderName = 'authHeaderName';
  static const _kUseBearer = 'useBearer';
  static const _kDefaultModel = 'defaultModel';
  static const _kSystemPrompt = 'systemPrompt';

  Future<void> saveSettings({
    required String endpoint,
    required String apiKey,
    String authHeaderName = 'Authorization',
    bool useBearer = true,
    String? defaultModel,
    String? systemPrompt,
  }) async {
    await _storage.write(key: _kEndpoint, value: endpoint);
    await _storage.write(key: _kApiKey, value: apiKey);
    await _storage.write(key: _kAuthHeaderName, value: authHeaderName);
    await _storage.write(key: _kUseBearer, value: useBearer.toString());
    await _storage.write(key: _kDefaultModel, value: defaultModel ?? '');
    await _storage.write(key: _kSystemPrompt, value: systemPrompt ?? '');
  }

  Future<Map<String, dynamic>> readSettings() async {
    final endpoint = await _storage.read(key: _kEndpoint) ?? '';
    final apiKey = await _storage.read(key: _kApiKey) ?? '';
    final authHeaderName =
        await _storage.read(key: _kAuthHeaderName) ?? 'Authorization';
    final useBearer =
        (await _storage.read(key: _kUseBearer) ?? 'true').toLowerCase() == 'true';
    final defaultModel = await _storage.read(key: _kDefaultModel) ?? '';
    final systemPrompt = await _storage.read(key: _kSystemPrompt) ?? '';
    return {
      'endpoint': endpoint,
      'apiKey': apiKey,
      'authHeaderName': authHeaderName,
      'useBearer': useBearer,
      'defaultModel': defaultModel,
      'systemPrompt': systemPrompt,
    };
  }

  Future<bool> isConfigured() async {
    final s = await readSettings();
    return s['endpoint'].toString().isNotEmpty && s['apiKey'].toString().isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
