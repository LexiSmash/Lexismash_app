<div align="center">

# 📱 LexiSmash App 🅰️

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/LexiSmash/Lexismash_app)
[![Open Source Love svg3](https://badges.frapsoft.com/os/v3/open-source.svg?v=103)](https://github.com/LexiSmash/Lexismash_app)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=plastic)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84.svg?logo=android&logoColor=white)](https://github.com/LexiSmash/Lexismash_app/releases)
[![Donate](https://img.shields.io/badge/PayPal-Donate%20to%20Author-blue.svg)](http://paypal.me/R0mb0)

The official mobile app of [**LexiSmash**](https://lexismash.it), a multiplayer word party game — draw letters, race the timer and build the best words with friends. **Your phone is the controller, a TV or monitor is the shared board.** A lightweight Flutter wrapper around lexismash.it, so the app always runs the latest version of the game. 🚀

  <a href="http://paypal.me/R0mb0">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/R0mb0/Support_the_dev_badge/blob/main/Badge/SVG/Support_the_dev_badge_Dark.svg">
      <source media="(prefers-color-scheme: light)" srcset="https://github.com/R0mb0/Support_the_dev_badge/blob/main/Badge/SVG/Support_the_dev_badge_Light.svg">
      <img alt="Saved you time? Support the dev" src="https://github.com/R0mb0/Support_the_dev_badge/blob/main/Badge/SVG/Support_the_dev_badge_Default.svg">
    </picture>
  </a>


## [👉 Click here to download the latest APK! 👈](https://github.com/LexiSmash/Lexismash_app/releases/latest)

</div>

---

## 🚀 Features

- **Always up to date**: the game runs at [lexismash.it](https://lexismash.it), so every new mode, theme or fix reaches the app instantly — no app update needed for game changes.
- **Offline screen**: no connection? A clear screen with a *Try again* button instead of a blank page, in your phone's language.
- **External links done right**: social networks, other websites, e-mail and phone links open in the right app; only the game, sign-in and payment pages stay inside.
- **Native sharing**: invite links, rooms and leaderboards open your phone's share menu (WhatsApp, Telegram, …).
- **Voice commands**: the game's voice controls work through your phone's own speech recognition.
- **File picking**: add your own songs to the jukebox, import room settings, load videos for the presentation mode.
- **Screen kept on**: while you're in a game, lobby or tournament the screen never turns off.
- **Android back gesture**: walks back through the game's pages; from the home screen it sends the app to the background.
- **Clean by design**: no Google Play Services, no Firebase SDK, no trackers inside the app — only free and open-source libraries.

## 🛠️ How it works

1. **WebView:** `app/lib/main.dart` opens [lexismash.it](https://lexismash.it) in a full-screen WebView (`webview_flutter`). All the game logic lives on the website, none of it in the app.
2. **Navigation rules:** only the game, its server, the sign-in providers (Google, GitHub, Facebook, Microsoft) and the payment page stay inside the app; every other link is handed to the system (`url_launcher`).
3. **Native bridge:** the app exposes a small JavaScript channel, `LexiSmashApp`. On the website, a tiny script uses it (only inside the app — in a normal browser it does nothing) to provide `navigator.share` and speech recognition, which Android's WebView doesn't have on its own:
   ```json
   { "type": "share", "title": "LexiSmash", "text": "Play with me!", "url": "https://lexismash.it/…" }
   ```
4. **Native helpers:** `share_plus` (share menu), `speech_to_text` (voice), `file_selector` (files), `wakelock_plus` (screen on), `permission_handler` (microphone) — all open source.

## 💡 Why this repository exists

- **Transparency**: the real LexiSmash game repository is private, but the app you install on your phone shouldn't be a black box — anyone can read exactly what it does and which permissions it asks for.
- **Free app stores**: an open-source app can be published on [F-Droid](https://f-droid.org) and [IzzyOnDroid](https://apt.izzysoft.de/fdroid/), which build or verify it from this code.
- **Reuse**: a small, documented example of a Flutter WebView wrapper with a native JavaScript bridge, useful for other web games.

## ⚡ Getting Started

### Download

- **GitHub Releases**: signed APKs in [Releases](https://github.com/LexiSmash/Lexismash_app/releases) — download, open, install.
- **IzzyOnDroid** and **F-Droid**: coming soon.

### Build from source

You need [Flutter](https://docs.flutter.dev/get-started/install) (stable channel) and the Android SDK with the NDK version Flutter asks for.

```bash
cd app
flutter pub get
flutter run                  # debug build on a connected phone
flutter build apk --release  # release APK in build/app/outputs/flutter-apk/
```

Release signing reads `app/android/key.properties`, which is never committed. Without it, the release build is signed with the debug key — fine for trying it on your own phone.

## 📂 Repository structure

```
Lexismash_app/
├── README.md, LICENSE, CONTRIBUTING.md, …   ← repository documents
├── .github/                                  ← Issue forms and Pull Request template
├── fastlane/metadata/android/                ← store listing: descriptions, icon, screenshots, changelogs
│   ├── en-US/
│   └── it-IT/
└── app/                                      ← the Flutter project
    ├── lib/main.dart                         ← the whole app
    ├── assets/icon/                          ← app icon (also adaptive and monochrome)
    ├── android/, ios/                        ← platform projects
    └── pubspec.yaml
```

## 🔐 Permissions

| Permission | Why |
|---|---|
| Internet | The game runs at lexismash.it |
| Microphone | Only for voice commands, asked the first time you use them |

The app relies on the LexiSmash online service, whose server is not open source (F-Droid label *NonFreeNet*).

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide. Short version: open a Pull Request with a focused change to the app (not to the game: the game lives on the website), explaining why. Every proposal is reviewed by hand before being merged — don't expect an instant or automatic merge. Bugs in the game itself can be reported from the website, through the link at the bottom of every page.

## 🔗 Relationship to the game

This repository contains **only the mobile app**. The game itself (a separate, private repository) is served by [lexismash.it](https://lexismash.it): the app shows it and adds the native features listed above. Game updates go live on the website and in the app at the same time; a new app release is needed only when the native part changes.

## 📄 License

- **Code** (the Flutter app in `app/`, this README and the other repository documents) is released under the [GNU General Public License v3.0](LICENSE) — use it, study it, modify it and share it, as long as your changes stay under the same license.
- **The LexiSmash name, logo and the game at lexismash.it** are not covered by this license.

<a href="https://github.com/R0mb0/Crafted_with_AI">
<picture>
<source media="(prefers-color-scheme: dark)" srcset="https://github.com/R0mb0/Crafted_with_AI/blob/main/Badge/SVG/CraftedWithAIDark.svg">
<source media="(prefers-color-scheme: light)" srcset="https://github.com/R0mb0/Crafted_with_AI/blob/main/Badge/SVG/NotMadeByAILight.svg">
<img alt="Crafted with AI" src="https://github.com/R0mb0/Crafted_with_AI/blob/main/Badge/SVG/CraftedWithAIDefault.svg">
</picture>
</a>
