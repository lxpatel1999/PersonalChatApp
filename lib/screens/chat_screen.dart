import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chat_controller.dart';
import '../state/settings_controller.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  bool _initialized = false;
  bool _promptedForConfig = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Load threads/messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatController>().init();
      });
    }
  }

  void _maybePromptForConfig(SettingsController settings) {
    if (settings.loaded && !settings.isConfigured && !_promptedForConfig) {
      _promptedForConfig = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        await settings.load();
        _promptedForConfig = false; // allow reprompt if still not configured
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final settings = context.watch<SettingsController>();

    _maybePromptForConfig(settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Chat'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text('Local history',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await settings.load();
            },
          )
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title: Text('Conversations',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: chat.threads.length,
                  itemBuilder: (context, i) {
                    final t = chat.threads[i];
                    final selected = t.id == chat.currentThread?.id;
                    return ListTile(
                      title: Text(t.title),
                      selected: selected,
                      onTap: () async {
                        chat.currentThread = t;
                        await chat.loadMessages();
                        if (mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New chat'),
                onTap: () async {
                  await chat.newThread();
                  if (mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete current chat'),
                onTap: () async {
                  await chat.deleteCurrentThread();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (!settings.isConfigured)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'First-time setup required. Settings will open to collect endpoint & API key.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (chat.error != null)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text('Error: ${chat.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: chat.messages.length,
              itemBuilder: (context, i) {
                final m = chat.messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(m.content),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      enabled: settings.isConfigured,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: chat.busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                    onPressed: chat.busy || !settings.isConfigured
                        ? null
                        : () async {
                            final text = _input.text.trim();
                            if (text.isEmpty) return;
                            _input.clear();
                            await chat.sendUserMessage(text);
                          },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
