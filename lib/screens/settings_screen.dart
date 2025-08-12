import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _endpoint;
  late TextEditingController _apiKey;
  late TextEditingController _authHeaderName;
  bool _useBearer = true;
  late TextEditingController _defaultModel;
  late TextEditingController _systemPrompt;

  @override
  void initState() {
    super.initState();
    final sc = context.read<SettingsController>();
    _endpoint = TextEditingController(text: sc.endpoint);
    _apiKey = TextEditingController(text: sc.apiKey);
    _authHeaderName = TextEditingController(text: sc.authHeaderName);
    _useBearer = sc.useBearer;
    _defaultModel = TextEditingController(text: sc.defaultModel);
    _systemPrompt = TextEditingController(text: sc.systemPrompt);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _apiKey.dispose();
    _authHeaderName.dispose();
    _defaultModel.dispose();
    _systemPrompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Clear all saved settings',
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await sc.clear();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared saved settings')),
              );
              setState(() {
                _endpoint.text = '';
                _apiKey.text = '';
                _authHeaderName.text = 'Authorization';
                _useBearer = true;
                _defaultModel.text = '';
                _systemPrompt.text = '';
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Enter your OpenAI-compatible chat completions endpoint and API key. '\
                'Example (OpenAI): https://api.openai.com/v1/chat/completions\n'\
                'Example (Azure): full chat-completions URL incl. deployment and api-version.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endpoint,
                decoration: const InputDecoration(
                  labelText: 'Chat API Endpoint (full URL)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Endpoint is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apiKey,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                ),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'API key is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _authHeaderName,
                decoration: const InputDecoration(
                  labelText: 'Auth Header Name (e.g., Authorization or api-key)',
                ),
              ),
              SwitchListTile(
                title: const Text('Use Bearer token (Authorization: Bearer <key>)'),
                value: _useBearer,
                onChanged: (v) => setState(() => _useBearer = v),
              ),
              const Divider(),
              TextFormField(
                controller: _defaultModel,
                decoration: const InputDecoration(
                  labelText: 'Default Model (optional; e.g., gpt-4o-mini)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _systemPrompt,
                decoration: const InputDecoration(
                  labelText: 'System Prompt (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true) return;
                  sc.endpoint = _endpoint.text;
                  sc.apiKey = _apiKey.text;
                  sc.authHeaderName = _authHeaderName.text;
                  sc.useBearer = _useBearer;
                  sc.defaultModel = _defaultModel.text;
                  sc.systemPrompt = _systemPrompt.text;
                  await sc.save();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
