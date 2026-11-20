# Contributing

Thanks for helping improve the LexiSmash mobile app! Here's how to propose a change.

## Before you start

- This repository contains **only the mobile app** (a Flutter wrapper around [lexismash.it](https://lexismash.it)). The game itself — rules, screens, dictionaries, the Store — lives on the website, in a separate private repository: changes to the game can't be made here.
- Every proposal is reviewed **by hand** by a human maintainer before it's accepted — don't expect an automatic or instant merge.
- One topic per Pull Request is better than one huge change mixing unrelated things: easier to review, more likely to be accepted quickly.
- The app must stay **free and open source, with no proprietary libraries** (no Google Play Services, no Firebase SDK, no analytics or ad SDKs), so it can keep being published on F-Droid.

## Build it first

```bash
cd app
flutter pub get
flutter run
```

You need [Flutter](https://docs.flutter.dev/get-started/install) (stable channel) and the Android SDK with the NDK version Flutter asks for. Please make sure the app still builds and runs on a real device or emulator before opening a Pull Request.

## Pull Request

1. Fork the repository and create a branch for your change.
2. Keep the change focused: `app/lib/main.dart`, a platform setting in `app/android/`, a dependency in `app/pubspec.yaml` (always commit the updated `app/pubspec.lock` too).
3. In the Pull Request description, explain **what** changes and **why**, and how you tested it.

## What will NOT be accepted

- Proprietary or tracking libraries (analytics, ads, crash reporters sending data to third parties).
- New permissions without a clear, user-facing reason.
- Changes that load content other than lexismash.it inside the app.
- Signing keys, passwords or any other secret (they must never be committed).

## Issue instead of a Pull Request

Found a bug in the app, or have an idea? Opening an Issue is perfectly fine — use the **App bug report** form. Problems with the game itself go to the [LexiSmash community repository](https://github.com/LexiSmash/.github/issues).

## Code of conduct

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
