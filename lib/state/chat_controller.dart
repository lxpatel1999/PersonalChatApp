import 'package:flutter/foundation.dart';
import '../services/chat_repository.dart';
import '../models/chat_models.dart';
import '../services/api_client.dart';
import '../services/storage_gc.dart';

class ChatController extends ChangeNotifier {
  final ChatRepository repo;
  final ChatApiClient api;
  ChatController({required this.repo, required this.api});

  ChatThread? currentThread;
  List<ChatThread> threads = [];
  List<ChatMessage> messages = [];
  bool busy = false;
  String? error;

  static const int maxContextChars = 24000; // prevent oversized payloads

  Future<void> init() async {
    // Run GC on startup
    await StorageGcService(repo: repo).run();

    threads = repo.getThreads();
    if (threads.isEmpty) {
      currentThread = await repo.createThread(title: 'New chat');
    } else {
      currentThread = threads.first;
    }
    await loadMessages();
    notifyListeners();
  }

  Future<void> newThread() async {
    currentThread = await repo.createThread(title: 'New chat');
    threads = repo.getThreads();
    messages = [];
    notifyListeners();
  }

  Future<void> deleteCurrentThread() async {
    if (currentThread == null) return;
    await repo.deleteThread(currentThread!.id);
    threads = repo.getThreads();
    currentThread = threads.isNotEmpty
        ? threads.first
        : await repo.createThread(title: 'New chat');
    await loadMessages();
    notifyListeners();
  }

  Future<void> loadMessages() async {
    if (currentThread == null) return;
    messages = repo.getMessages(currentThread!.id);
    notifyListeners();
  }

  List<Map<String, String>> _buildContextMessages() {
    final all = messages
        .map((m) => {
              'role': m.role,
              'content': m.content,
            })
        .toList();

    int total = 0;
    final kept = <Map<String, String>>[];
    for (final m in all.reversed) {
      final len = (m['content'] ?? '').length;
      if (kept.isNotEmpty && (total + len) > maxContextChars) break;
      kept.add(m);
      total += len;
    }
    return kept.reversed.toList();
  }

  String _titleFrom(String userFirst, String assistantFirst) {
    final merged = (userFirst + ' ' + assistantFirst).trim();
    final t = merged.length > 60 ? merged.substring(0, 60) : merged;
    return t.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> sendUserMessage(String content) async {
    if (currentThread == null) return;
    error = null;
    await repo.addMessage(
      threadId: currentThread!.id,
      role: 'user',
      content: content,
    );
    messages = repo.getMessages(currentThread!.id);
    notifyListeners();

    busy = true;
    notifyListeners();
    try {
      final completion = await api.createChatCompletion(
        messages: _buildContextMessages(),
      );
      await repo.addMessage(
        threadId: currentThread!.id,
        role: 'assistant',
        content: completion,
      );
      messages = repo.getMessages(currentThread!.id);

      if ((currentThread?.title ?? '') == 'New chat' && messages.length >= 2) {
        final userFirst = messages
            .firstWhere((m) => m.role == 'user', orElse: () => messages.first)
            .content;
        final assistantFirst = messages
            .firstWhere((m) => m.role == 'assistant', orElse: () => messages.last)
            .content;
        final newTitle = _titleFrom(userFirst, assistantFirst);
        await repo.renameThread(currentThread!.id, newTitle);
        threads = repo.getThreads();
      }

      // Run GC after each assistant reply
      await StorageGcService(repo: repo).run();
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
