# Agent Guide

WanderStamp is a Flutter Web app backed by Firebase. It lets people request, track, and confirm receipt of handwritten postcards; admin-only tools manage requests and shipment status.

## Startup Workflow

Before writing code:

1. Read this file, `README.md`, `feature_list.json`, and `progress.md`.
2. Review the files and tests closest to the requested behavior. Treat Firestore rules and address privacy as security boundaries.
3. Run `flutter pub get`, then the relevant test. Run `./init.sh` (or its four commands individually on Windows) before completing a feature.
4. Check `git status --short`; preserve unrelated user changes.

## Working Rules

- **One feature at a time:** set exactly one feature in `feature_list.json` to `in-progress` before editing.
- **Stay in scope:** change only files needed for that feature. Do not alter Firebase configuration, deployed rules, credentials, or production data unless the user explicitly requests it.
- **Protect personal data:** addresses and recipient-identifying data must never be exposed in public views, logs, test fixtures, screenshots, or error messages.
- **Use existing patterns:** keep UI work in `lib/views` or `lib/widgets`; retain domain models in `lib/models` and Firebase access in `lib/services`.
- **Keep tests aligned:** add or update focused tests under `test/` for behavior changes. Do not weaken tests just to make them pass.
- **Record evidence:** update the feature tracker and progress log after verification.

## Repository Map

- `lib/main.dart` and `lib/home_nav.dart`: application entry and navigation
- `lib/views/`: request, tracking, receipt, and admin screens
- `lib/widgets/`: reusable presentation components
- `lib/models/`: postcard data model
- `lib/services/firebase_service.dart`: Firestore access boundary
- `lib/providers/auth_provider.dart`: admin authentication state
- `test/`: unit and widget tests; `integration_test/`: end-to-end coverage

## Verification Commands

Run the full gate from a Bash-compatible shell:

```bash
./init.sh
```

The gate runs:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web`

For a focused change, run its closest test before the full gate. The web build is required for UI, routing, asset, dependency, or Firebase-bootstrap changes.

## Definition of Done

A feature is done only when all apply:

- Requested behavior and its focused tests are complete.
- `flutter analyze`, `flutter test`, and any applicable `flutter build web` have passed.
- Firebase access remains least-privilege and addresses remain private.
- `feature_list.json` and `progress.md` contain the command results and remaining risks.
- The repository is restartable: a later agent can begin from this guide and `./init.sh`.

## End of Session

1. Update the active feature's status, evidence, and dependencies in `feature_list.json`.
2. Update `progress.md` and, for unfinished or multi-session work, `session-handoff.md` with changed files, blockers, and the next action.
3. Leave unrelated changes intact and report any verification that was not run.
