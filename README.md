# 🌟 GratiStellar

**Build your universe of thankfulness with a peaceful gratitude tracker**

A beautiful, cosmic-themed gratitude journaling app that transforms your daily reflections into a personal galaxy of thankfulness.

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red)]()
[![Version](https://img.shields.io/badge/Version-1.0.0-green)]()

---

## ✨ Features

- 🌌 **Cosmic Visualization** - Your gratitudes become stars in your personal universe
- 📱 **Offline-First** - Works perfectly without internet, syncs when connected
- 🔐 **Encrypted Storage** - All data encrypted locally and in transit
- ☁️ **Cloud Sync** - Seamlessly sync across all your devices via Firebase
- 🌈 **Customizable** - Choose custom colors for your gratitude stars
- 🗂️ **Galaxy Collections** - Organize gratitudes into themed collections
- 🧘 **Mindfulness Mode** - Cycle through your gratitudes for peaceful reflection
- 💾 **Backup & Restore** - Export encrypted backups of all your data
- 🌍 **Multi-language** - Currently supports English (Spanish & French in progress)
- ♿ **Accessibility** - Full support for screen readers, font scaling, and motion preferences
- 🎨 **Beautiful UI** - Peaceful animations and cosmic theme
- 🗑️ **Smart Trash** - Deleted items recoverable for 30 days

---

## 📱 Screenshots

*[Add screenshots here when available]*

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.9.2 or higher
- **Dart SDK**: 3.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** (for cloud sync features)
- **Google Cloud Project** (for Google Sign-In)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/[YOUR-USERNAME]/gratistellar.git
   cd gratistellar
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** (Required for cloud features)

   a. Create a Firebase project at https://console.firebase.google.com
   
   b. Add Android app to Firebase project:
      - Package name: `grati.stellar.app`
      - Download `google-services.json` → place in `android/app/`
   
   c. Enable Firebase services:
      - **Authentication** (Anonymous & Email/Password)
      - **Cloud Firestore** (Database)
      - **Crashlytics** (Crash reporting)
      - **Analytics** (Usage tracking)
   
   d. Deploy Firestore security rules:
      ```bash
      firebase deploy --only firestore:rules
      ```
   
   e. Deploy Firestore indexes:
      ```bash
      firebase deploy --only firestore:indexes
      ```

4. **Configure Google Sign-In** (Optional but recommended)

   a. Get SHA-1 certificate fingerprint:
      ```bash
      keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
      ```
   
   b. Add SHA-1 to Firebase project settings
   
   c. Enable Google Sign-In in Firebase Authentication

5. **Create environment file**
   ```bash
   touch .env
   # Add any environment-specific variables
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Project Structure

```
lib/
├── core/                          # Core utilities and configurations
│   ├── accessibility/             # Accessibility helpers
│   ├── animation/                 # Animation managers
│   ├── config/                    # App constants
│   ├── security/                  # Input validation, rate limiting
│   └── utils/                     # Logger, utilities
├── features/                      # Feature modules
│   ├── backup/                    # Backup/restore feature
│   │   ├── data/repositories/     # Backup data operations
│   │   ├── domain/usecases/       # Backup business logic
│   │   └── presentation/widgets/  # Backup UI
│   └── gratitudes/                # Main gratitude feature
│       ├── data/                  # Data layer
│       │   ├── datasources/       # Local & remote data sources
│       │   └── repositories/      # Repository implementations
│       ├── domain/                # Business logic
│       │   └── usecases/          # Use cases
│       └── presentation/          # UI layer
│           ├── state/             # State management (Provider)
│           └── widgets/           # UI components
├── l10n/                          # Localization files
├── screens/                       # Main app screens
├── services/                      # App services
│   ├── auth_service.dart          # Authentication
│   ├── firestore_service.dart     # Cloud database
│   ├── crashlytics_service.dart   # Crash reporting
│   └── feedback_service.dart      # User feedback
├── widgets/                       # Shared widgets
└── main.dart                      # App entry point
```

### Architecture

- **Clean Architecture** - Separation of concerns with clear layers
- **Feature-First** - Organized by features, not layers
- **Provider** - State management
- **Repository Pattern** - Abstract data sources
- **Use Cases** - Encapsulated business logic

---

## 🔧 Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

### Code Generation

If you add new localizations:
```bash
flutter gen-l10n
```

---

## 📦 Dependencies

### Core
- **flutter_localizations** - Internationalization
- **provider** - State management
- **intl** - Date formatting

### Firebase
- **firebase_core** - Firebase initialization
- **firebase_auth** - User authentication
- **cloud_firestore** - Cloud database
- **firebase_crashlytics** - Crash reporting
- **firebase_analytics** - Usage analytics

### Storage & Security
- **shared_preferences** - Simple key-value storage
- **flutter_secure_storage** - Encrypted secure storage
- **archive** - Data compression
- **crypto** - Encryption utilities

### Data Management
- **file_picker** - Backup file selection
- **share_plus** - Share backup files
- **path_provider** - File system paths

### UI
- **flutter_svg** - SVG rendering
- **vector_math** - Math utilities for graphics

### Utilities
- **package_info_plus** - App version info
- **device_info_plus** - Device information
- **connectivity_plus** - Network status

---

## 🔐 Security

- **Encrypted Storage** - All local data encrypted with AES-256
- **Firebase Security Rules** - User data isolated and validated
- **Input Validation** - All user input sanitized
- **Rate Limiting** - Protection against abuse
- **Secure Authentication** - Firebase Auth with email/password + anonymous
- **HTTPS Only** - All network communication encrypted

---

## 🌍 Localization

Currently supported:
- 🇺🇸 English (complete)
- 🇪🇸 Spanish (in progress)
- 🇫🇷 French (in progress)

### Adding New Languages

1. Create `lib/l10n/app_[locale].arb`
2. Copy strings from `app_en.arb`
3. Translate all strings
4. Run `flutter gen-l10n`
5. Add locale to `supportedLocales` in `main.dart`

---

## 📄 Legal

- **Privacy Policy**: [INSERT URL]
- **Terms of Service**: [INSERT URL]
- **Data Deletion**: [INSERT URL]

See `legal/` directory for full documents.

---

## 🤝 Contributing

This is currently a private project. Contributions are not being accepted at this time.

---

## 🐛 Bug Reports & Feature Requests

Email: [INSERT SUPPORT EMAIL]

Please include:
- Device model & OS version
- App version
- Steps to reproduce
- Screenshots (if applicable)

---

## 📝 Changelog

### v1.0.0 (2025-01-XX)
- 🎉 Initial production release
- ✨ Core gratitude journaling features
- 🌌 Galaxy collections
- 💾 Backup & restore
- ☁️ Cloud sync
- 🔐 Encrypted storage
- 🧘 Mindfulness mode
- ♿ Accessibility features
- 🌍 Multi-language support (English)

---

## 📊 Performance

- **App Size**: ~15-20 MB (release build)
- **Min Android Version**: API 21 (Android 5.0 Lollipop)
- **Target Android Version**: API 34 (Android 14)
- **Memory Usage**: ~50-80 MB average
- **Startup Time**: <2 seconds on modern devices

---

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev) - Google's UI toolkit
- [Firebase](https://firebase.google.com) - Google's app platform
- [Material Design](https://material.io) - Design system

---

## 📧 Contact

**Support**: [INSERT SUPPORT EMAIL]  
**Website**: [INSERT WEBSITE]  
**Privacy**: [INSERT PRIVACY POLICY URL]

---

## ⚖️ License

Proprietary - All rights reserved.

This software and its source code are confidential and proprietary. Unauthorized copying, distribution, or modification is strictly prohibited.

---

**Made with ❤️ and gratitude**
