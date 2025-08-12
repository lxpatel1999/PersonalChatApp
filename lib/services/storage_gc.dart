import '../services/chat_repository.dart';
import '../models/chat_models.dart';

/// Simple on-device garbage collector for chat history.
/// Trims oldest threads/messages using fixed policies so local storage stays bounded.
class StorageGcService {
  final ChatRepository repo;
  final int maxThreads; // keep newest N threads
  final int maxMessagesPerThread; // keep newest N messages per thread
  final int maxTotalChars; // global char cap across all messages

  const StorageGcService({
    required this.repo,
    this.maxThreads = 50,
    this.maxMessagesPerThread = 500,
    this.maxTotalChars = 500000,
  });

  Future<void> run() async {
    // 1) Trim threads count
    final threads = repo.getThreads(); // already sorted newest->oldest
    if (threads.length > maxThreads) {
      for (int i = maxThreads; i < threads.length; i++) {
        await repo.deleteThread(threads[i].id);
      }
    }

    // 2) Trim per-thread messages
    final keptThreads = repo.getThreads();
    for (final t in keptThreads) {
      final msgs = repo.getMessages(t.id); // oldest->newest order
      if (msgs.length > maxMessagesPerThread) {
        final toDelete = msgs.sublist(0, msgs.length - maxMessagesPerThread);
        for (final m in toDelete) {
          await repo.deleteMessage(m.id);
        }
      }
    }

    // 3) Global character cap
    final all = repo.getAllMessages(); // oldest->newest
    int totalChars = 0;
    for (final m in all) {
      totalChars += m.content.length;
    }
    if (totalChars > maxTotalChars) {
      int i = 0;
      while (i < all.length && totalChars > maxTotalChars) {
        final m = all[i];
        await repo.deleteMessage(m.id);
        totalChars -= m.content.length;
        i++;
      }
    }
  }
}
