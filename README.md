# Fattura Facile — Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](./LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-blue?style=for-the-badge)](#architecture--tech-stack)

---

## 1. Project Overview & Purpose

**Fattura Facile Mobile** is a cross-platform client tailored for freelancers, small business owners, consultants, and accounting professionals. The application simplifies and streamlines electronic and standard invoicing workflows, enabling users to generate, track, and manage commercial invoices, customer directories, and tax-compliant documents directly from their mobile or desktop devices.

### Primary Capabilities & Objectives
- **Invoice Generation & Lifecycle Management**: Create, view, revise, and dispatch digital invoices and receipts with automated tax calculations.
- **Client & Directory Records**: Maintain client details, VAT numbers, tax IDs (*Codice Fiscale*), and billing addresses.
- **Status & Payment Tracking**: Monitor invoice statuses (draft, issued, paid, overdue) with clear financial summaries.
- **Multi-Platform Flexibility**: Unified codebase delivering a native user experience across iOS, Android, Web, and Desktop environments.

---

## 2. Architecture & Tech Stack

The application is built using the **Flutter** framework and **Dart**, following an architectural separation that cleanly isolates platform integrations, business logic, and UI components.

### Core Technology Stack
- **Framework**: [Flutter](https://flutter.dev/) (SDK `>=3.13.5`)
- **Language**: [Dart](https://dart.dev/)
- **UI Guidelines**: Material Design 3 (`uses-material-design: true`) and iOS Cupertino styling (`cupertino_icons: ^1.0.8`)
- **Linting & Code Quality**: Recommended Dart & Flutter rules configured via [`analysis_options.yaml`](./src/analysis_options.yaml) and `flutter_lints`

### Architectural Design & Standards
The project adopts modern Clean Architecture and feature-driven design principles:
- **Presentation Layer**: Stateless and Stateful widgets encapsulating responsive layouts, theme adaptations, and UI event handling.
- **State Management**: Reactive state management pattern isolating business rules from platform view rendering.
- **Data & Domain Abstraction**: Decoupled repository patterns and service layers facilitating API communication, persistent caching, and offline support.
- **Workspace Decoupling**: Root-level project configurations, repository rules, and security controls wrap the dedicated Flutter source directory located inside [`src/`](./src/).

---

## 3. Repository Structure

```text
fattura-facile/mobile/
├── .copilotignore              # AI tooling exclusions & secret boundary enforcement
├── .gitattributes              # Line ending and Git path normalization
├── .gitignore                  # Global VCS ignore policies (ephemeral, secrets, builds)
├── LICENSE                     # MIT License specification
├── README.md                   # Project documentation & architectural manual
└── src/                        # Flutter workspace directory
    ├── analysis_options.yaml   # Static analysis and linting rules
    ├── pubspec.yaml            # Package manifest, dependencies, and environment constraints
    ├── pubspec.lock            # Exact resolved dependency graph
    ├── android/                # Android native host project & Gradle configuration
    ├── ios/                    # iOS native host project & CocoaPods configuration
    ├── linux/                  # Linux desktop native project runners
    ├── macos/                  # macOS native desktop host project
    ├── web/                    # Web runner, index.html, and PWA manifest
    ├── windows/                # Windows desktop native C++ runner
    ├── lib/                    # Application source code
    │   └── main.dart           # Application entrypoint & base widget tree
    └── test/                   # Automated unit, widget, and integration test suites
```

---

## 4. Getting Started / Prerequisites

### Prerequisites
Before running the application, ensure your environment meets the following requirements:
1. **Flutter SDK**: Version `^3.13.5` or higher installed. Verify your installation:
   ```bash
   flutter doctor
   ```
2. **Platform Toolchains**:
   - **Android**: Android Studio with SDK build tools and an active emulator or physical device.
   - **iOS/macOS**: Xcode (latest stable recommended) and CocoaPods installed (for macOS/iOS targets).
   - **Desktop/Web**: Chrome (for Web) or native build prerequisites (Visual Studio C++ for Windows, Clang/CMake for Linux).

### Installation & Execution

All Flutter CLI commands must be executed from within the [`src/`](./src/) directory:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/fattura-facile-mobile.git
   cd fattura-facile/mobile/src
   ```

2. **Install project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify static analysis**:
   ```bash
   flutter analyze
   ```

4. **Run automated tests**:
   ```bash
   flutter test
   ```

5. **Launch the application**:
   ```bash
   # Run on the default connected device
   flutter run

   # Or target a specific platform
   flutter run -d chrome
   flutter run -d windows
   flutter run -d android
   ```

---

## 5. Configuration & Environment

### Environment Variables & Secrets
To separate operational configuration from the codebase:
- Use an environment configuration file (e.g., `src/.env`) for backend API URLs, authentication tenant keys, and environment flags.
- When introducing environment configurations, establish a `src/.env.example` template with redacted placeholders for onboarding developers.
- Both root-level and workspace `.gitignore` rules prevent private files (`.env`, `.env.*`, keystores, and credentials) from being committed to source control.

### Platform Credentials & Signing
- **Android**: Place local developer properties in `src/android/local.properties` and keystore configurations in `src/android/key.properties` (strictly ignored by VCS).
- **iOS / Firebase**: If using Firebase services, supply `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their designated platform folders; these paths are governed under ignore policies.

---

## 6. License & Acknowledgments

This project is licensed under the terms of the **MIT License**. For full terms, refer to the [LICENSE](./LICENSE) file.

---
*Maintained with strict software engineering standards for the Fattura Facile platform.*
