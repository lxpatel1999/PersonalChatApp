import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';

class ChatRepository {
  static const threadsBoxName = 'threads';
  static const messagesBoxName = 'messages';

  late Box<ChatThread> _threadsBox;
  late Box<ChatMessage> _messagesBox;
  final _uuid = const Uuid();

  static Future<ChatRepository> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ChatThreadAdapter());
    Hive.registerAdapter(ChatMessageAdapter());

    final repo = ChatRepository();
    repo._threadsBox = await Hive.openBox<ChatThread>(threadsBoxName);
    repo._messagesBox = await Hive.openBox<ChatMessage>(messagesBoxName);
    return repo;
  }

  Future<ChatThread> createThread({String? title}) async {
    final id = _uuid.v4();
    final thread = ChatThread(
      id: id,
      title: title ?? 'New chat',
      createdAt: DateTime.now(),
    );
    await _threadsBox.put(id, thread);
    return thread;
  }

  Future<void> renameThread(String threadId, String title) async {
    final t = _threadsBox.get(threadId);
    if (t != null) {
      t.title = title;
      await t.save();
    }
  }

  List<ChatThread> getThreads() {
    final list = _threadsBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> deleteThread(String threadId) async {
    final msgs = _messagesBox.values.where((m) => m.threadId == threadId).toList();
    for (final m in msgs) {
      await m.delete();
    }
    await _threadsBox.delete(threadId);
  }

  Future<void> deleteAll() async {
    await _messagesBox.clear();
    await _threadsBox.clear();
  }

  Future<ChatMessage> addMessage({
    required String threadId,
    required String role,
    required String content,
  }) async {
    final id = _uuid.v4();
    final msg = ChatMessage(
      id: id,
      threadId: threadId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
    await _messagesBox.put(id, msg);
    return msg;
  }

  List<ChatMessage> getMessages(String threadId) {
    final msgs = _messagesBox.values.where((m) => m.threadId == threadId).toList();
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  List<ChatMessage> getAllMessages() {
    final msgs = _messagesBox.values.toList();
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  Future<void> deleteMessage(String id) async {
    await _messagesBox.delete(id);
  }
}
