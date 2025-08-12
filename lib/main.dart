import 'package:flutter/material.dart';
import 'app.dart';
import 'services/chat_repository.dart';
import 'state/settings_controller.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await ChatRepository.init();
  final settings = SettingsController(SecureStorageService());
  await settings.load();
  runApp(LlmChatApp(repo: repo, settings: settings));
}
