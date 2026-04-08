# Project Info

## Architecture

- UI: Flutter Web (Material 3).
- State: `provider` (`AuthProvider` for admin auth state).
- Backend: Firebase Auth + Cloud Firestore.
- Entry: `lib/main.dart` -> `bootstrapApp()` -> `WanderStampApp`.

## Core Folders

- `lib/models`: domain data objects.
- `lib/services`: Firestore and auth integration.
- `lib/providers`: app state providers.
- `lib/views`: pages and route-level widgets.
- `lib/widgets`: reusable UI blocks.
- `test`: unit/widget tests and route/bootstrap coverage.

## Main Data Model

`Postcard` stores request lifecycle fields used by UI and admin:

- identity: `id`, `nickname`, `trackingCode`
- request details: `address`, `topic`, `message`, `campaign`, `giftMode`
- timeline: `status`, `createdAt`, `sentAt`, `receivedAt`
- display data: `travelerNote`, `previewOnWall`, `wallMessage`
- map data: `sentLat`, `sentLng`

## Runtime Notes

- Route arguments allow deep-link startup with:
  - `initialTab`
  - `initialTrackQuery`
- Test mode supports offline map tile behavior by injecting a mock tile provider in map tests.
- Bootstrap logic is test-injectable (`bootstrapApp`) so startup is unit-testable without changing production behavior.

## Verification Commands

```bash
dart format lib test
flutter analyze
flutter test
flutter test --coverage
```
