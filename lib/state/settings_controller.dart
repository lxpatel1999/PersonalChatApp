import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';

class SettingsController extends ChangeNotifier {
  final SecureStorageService storage;
  SettingsController(this.storage);

  String endpoint = '';
  String apiKey = '';
  String authHeaderName = 'Authorization';
  bool useBearer = true;
  String defaultModel = '';
  String systemPrompt = '';

  bool loaded = false;

  Future<void> load() async {
    final s = await storage.readSettings();
    endpoint = s['endpoint'] ?? '';
    apiKey = s['apiKey'] ?? '';
    authHeaderName = s['authHeaderName'] ?? 'Authorization';
    useBearer = s['useBearer'] ?? true;
    defaultModel = s['defaultModel'] ?? '';
    systemPrompt = s['systemPrompt'] ?? '';
    loaded = true;
    notifyListeners();
  }

  bool get isConfigured =>
      endpoint.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  Future<void> save() async {
    await storage.saveSettings(
      endpoint: endpoint.trim(),
      apiKey: apiKey.trim(),
      authHeaderName:
          authHeaderName.trim().isEmpty ? 'Authorization' : authHeaderName.trim(),
      useBearer: useBearer,
      defaultModel: defaultModel.trim().isEmpty ? null : defaultModel.trim(),
      systemPrompt: systemPrompt.trim().isEmpty ? null : systemPrompt.trim(),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    await storage.clear();
    await load();
  }
}
