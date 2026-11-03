# NOVEL FORGE AI — Integrated MVP Source

Private, single-author Android-first novel studio. This is an integrated **source package**, not an APK.

## Included in this MVP
- Flutter mobile shell and novel project creation/listing.
- Story Architect outline generation through a server-side OpenAI Responses API adapter.
- Story Intelligence: characters, relationships, canon facts, events, chapter memories and author decisions.
- Novel Writer: continuity-aware scene context, prompt composition and draft checks.
- Literary Editor: eight review modes, local manuscript checks and version comparison. AI review currently returns a structured prompt unless a synchronous server-side `ai_generate` adapter is connected.
- Arabic, English and French language selection foundations.

## Run the API
1. Copy `.env.example` to `.env` and set `OPENAI_API_KEY` on the server only.
2. `docker compose up --build`
3. API docs: `http://localhost:8000/docs`; health: `http://localhost:8000/health`.

## Run the Flutter app
Install Flutter 3.22+ and Android SDK, then:
```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
For a physical phone, use the computer's LAN IP instead of `10.0.2.2`.

## Build an Android APK
With Flutter and Android SDK installed:
```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:8000
```
The APK is written to `mobile/build/app/outputs/flutter-apk/app-release.apk`.

## Important limitations before real-world deployment
This is a development MVP. Authentication and per-project ownership enforcement are not implemented; do not expose the API publicly. Add authentication, authorization, database migrations, backups, rate limits, request-size limits, robust AI job queue/retries, semantic continuity checks, and automated integration tests before production. The app currently uses a simple API base URL and requires network access for AI features. The backend defaults to SQLite; Docker Compose can use PostgreSQL.

## Verification status
Python syntax compilation is performed on the included backend. Flutter/Android compilation is **not verified in this environment** because Flutter and Android SDK are not installed here. No APK is included.
