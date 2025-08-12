# LLM Chat (Flutter) — v2

**Updates in this build**
- First-run prompt: automatically opens **Settings** on first launch until endpoint & API key are provided.
- Local storage **garbage collector**: trims old chats/messages so storage doesn't grow unbounded.

## Quick Start

```bash
flutter create llm_chat
cd llm_chat
# Replace lib/ and pubspec.yaml with files from this ZIP
flutter pub get
flutter run -d ios|android|windows
```

## Configure (first run)
You'll be taken directly to **Settings** to enter:
- Endpoint (OpenAI: `https://api.openai.com/v1/chat/completions`; Azure: full chat-completions URL)
- API key
- Auth header name + Bearer toggle
- Optional model & system prompt

## Storage GC policy (defaults)
- Keep up to **50 threads**
- Keep up to **500 messages per thread**
- Keep up to **500,000 characters** across all messages

You can change these constants in `lib/services/storage_gc.dart`.
