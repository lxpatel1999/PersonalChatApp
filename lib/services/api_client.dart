import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApiClient {
  final String endpoint; // full URL to chat completions
  final String apiKey;
  final String authHeaderName; // e.g., 'Authorization' or 'api-key'
  final bool useBearer;
  final String? defaultModel;
  final String? systemPrompt;

  ChatApiClient({
    required this.endpoint,
    required this.apiKey,
    this.authHeaderName = 'Authorization',
    this.useBearer = true,
    this.defaultModel,
    this.systemPrompt,
  });

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authHeaderName.toLowerCase() == 'authorization' && useBearer) {
      headers['Authorization'] = 'Bearer $apiKey';
    } else {
      headers[authHeaderName] = apiKey;
      if (authHeaderName.toLowerCase() == 'authorization' && !useBearer) {
        headers['Authorization'] = apiKey;
      }
    }
    return headers;
  }

  /// messages: [{'role': 'system'|'user'|'assistant', 'content': '...'}]
  /// Returns assistant's reply string.
  Future<String> createChatCompletion({
    required List<Map<String, String>> messages,
    String? modelOverride,
    double? temperature,
  }) async {
    final List<Map<String, String>> messagesOut = [];
    if ((systemPrompt ?? '').trim().isNotEmpty) {
      messagesOut.add({'role': 'system', 'content': systemPrompt!.trim()});
    }
    messagesOut.addAll(messages);

    final body = <String, dynamic>{
      if ((modelOverride ?? defaultModel)?.isNotEmpty ?? false)
        'model': (modelOverride ?? defaultModel),
      'messages': messagesOut,
      if (temperature != null) 'temperature': temperature,
    };

    final uriStr = endpoint.trim();
    if (uriStr.isEmpty) {
      throw Exception('Endpoint is empty. Configure Settings.');
    }
    final res = await http.post(
      Uri.parse(uriStr),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: '
          '${res.body.isNotEmpty ? res.body : res.reasonPhrase}');
    }

    final data = jsonDecode(res.body);
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final msg = choices.first['message'];
      if (msg is Map && msg['content'] is String) {
        return msg['content'] as String;
      }
    }

    throw Exception('Unexpected response shape: ${res.body}');
  }
}
