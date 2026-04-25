![GitHub Release](https://img.shields.io/github/v/release/RobinNormy/BudgetBuddy?style=for-the-badge&color=green)
# BudgetBuddy

A personal finance management app built with Flutter to help you track income, expenses, and budgets with beautiful visual charts and analytics.

## Features

- **Transaction Tracking** - Record income and expenses with categories
- **Budget Management** - Set monthly budgets and track spending
- **Visual Analytics** - Beautiful charts showing your financial overview
- **Category Management** - Organize transactions by custom categories
- **Multi-Currency Support** - Support for various currencies
- **Firebase Integration** - Cloud storage and authentication
- **Google Sign-In** - Quick and secure authentication

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later)
- Firebase project configured
- Android SDK / Xcode (for iOS/macOS builds)
## 📥 Download & Install
You can download the latest version of BudgetBuddy from the [Releases Page](https://github.com/RobinNormy/BudgetBuddy/releases).

**Which version should I choose?**
* **Modern Phones:** Download `BudgetBuddy_Modern.apk` (ARM64).
* **Older/Budget Phones:** Download `BudgetBuddy_Legacy.apk` (ARMv7).

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd budget_buddy
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add Android and iOS apps to your project
   - Download `google-services.json` for Android and place in `android/app/`
   - Download `GoogleService-Info.plist` for iOS and place in `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── auth.dart               # Authentication logic
├── budget_service.dart     # Budget management
├── budget_utils.dart       # Budget utilities
├── budget_widgets.dart     # Budget UI components
├── category_utils.dart     # Category management
├── currency_utils.dart     # Currency handling
├── home_chart.dart        # Chart visualizations
├── stats.dart              # Statistics & analytics
├── streams.dart            # Data streams
├── theme_provider.dart     # Theme management
├── transactions.dart       # Transaction handling
├── reusable.dart           # Reusable components
├── all_transactions.dart   # Transaction list view
├── profile_reusablecards.dart # Profile components
└── screens/                # App screens
```

## Tech Stack

- **Framework**: Flutter
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Charts**: fl_chart
- **State Management**: Provider
- **Authentication**: Firebase Auth, Google Sign-In

## Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### macOS
```bash
flutter build macos --release
```

### Linux
```bash
flutter build linux --release
```

## License

This project is licensed under the MIT License.

## Author

Robinson - [GitHub](https://github.com)
