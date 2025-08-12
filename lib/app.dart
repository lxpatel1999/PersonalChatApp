import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'state/chat_controller.dart';
import 'state/settings_controller.dart';
import 'services/chat_repository.dart';
import 'services/secure_storage_service.dart';
import 'services/api_client.dart';

class LlmChatApp extends StatelessWidget {
  final ChatRepository repo;
  final SettingsController settings;
  const LlmChatApp({super.key, required this.repo, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProxyProvider<SettingsController, ChatController>(
          create: (_) => ChatController(
            repo: repo,
            api: ChatApiClient(endpoint: '', apiKey: ''),
          ),
          update: (_, settings, previous) {
            final api = ChatApiClient(
              endpoint: settings.endpoint,
              apiKey: settings.apiKey,
              authHeaderName: settings.authHeaderName,
              useBearer: settings.useBearer,
              defaultModel:
                  (settings.defaultModel.isEmpty) ? null : settings.defaultModel,
              systemPrompt:
                  (settings.systemPrompt.isEmpty) ? null : settings.systemPrompt,
            );
            final ctrl = previous ?? ChatController(repo: repo, api: api);
            return ChatController(repo: ctrl.repo, api: api);
          },
        ),
      ],
      child: MaterialApp(
        title: 'LLM Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ChatScreen(),
      ),
    );
  }
}
