import 'package:hive/hive.dart';

part 'chat_models.g.dart';

@HiveType(typeId: 1)
class ChatThread extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
  });
}

@HiveType(typeId: 2)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String threadId;

  /// 'user' | 'assistant' | 'system'
  @HiveField(2)
  String role;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
  });
}
