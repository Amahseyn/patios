# Patios (iOS)

Pet care companion for daily tasks, health records, AI assistance, and pet profiles. Household data lives on device and can sync with the Patios API.

Sibling apps: Android `../CatAndroid`, API `../backend`. Do not add Python or FastAPI files here.

## Tabs

| Tab | Purpose |
| --- | --- |
| **Home** | Owner overview — greeting, pet strip, today’s care progress, upcoming health, quick actions |
| **Care** | Daily checklist, templates, meal logging, reminders |
| **Health** | Vaccines, vet visits, nutrition / weight / activity modules |
| **Assist** | AI chats and activity insights |
| **You** | Account, pets, appearance, membership, legal |

## What is solid now

- Pets, care tasks, and health records are stored in an on-device SQLite database (`Application Support/Patios/patios.sqlite`).
- Shared design system (`AppTheme`, cards, empty / loading / error states, Realm / Fantasy chrome).
- Sign in and sync with `GET/PUT /api/v1/sync`.
- The AI assistant uses `/api/v1/assistant/sessions` when signed in, with on-device fallback.

## Run

Open `CatIos.xcodeproj` in Xcode and run the **CatIos** scheme.

```bash
xcodebuild -scheme CatIos -destination 'platform=iOS Simulator,name=iPhone 17' build
```

To sync, start the API from `../backend`, then sign in from **You** (simulator default API: `http://127.0.0.1:8000/api/v1`).

## Secrets

Do not commit real passwords. `CatIos/Config/DevAuthConfig.swift` is DEBUG-only and should stay empty or local. See `DevAuthConfig.example.swift` for the shape.
