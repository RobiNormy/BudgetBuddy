# BudgetBuddy

![GitHub Release](https://img.shields.io/github/v/release/RobinNormy/BudgetBuddy?style=for-the-badge&color=green)

BudgetBuddy is a Flutter personal finance app for tracking income, expenses, budgets, and spending trends in one place. It uses Firebase for authentication and cloud data, includes a custom liquid glass navigation bar, and now also includes a live currency converter.

## Features

- Transaction tracking for income and expenses
- Monthly budget creation and budget health tracking
- Visual analytics with charts and category breakdowns
- Wallet setup with preferred currency selection
- Live currency converter with exchange-rate lookup
- Firebase authentication with Google Sign-In
- Cloud sync with Firestore and Firebase Storage
- Profile insights, theme switching, and account actions
- First-run onboarding and guided in-app tutorial

## Currency Converter

The app includes a bottom-sheet currency converter available from the profile screen.

- Supports multiple currencies including `KES`, `USD`, `EUR`, `GBP`, `UGX`, `TZS`, `ZAR`, `NGN`, `CNY`, `JPY`, `AED`, and `INR`
- Uses live rates from ExchangeRate-API
- Swaps source and target currencies instantly
- Debounced conversion while typing

## Main Screens

- `Home`: balance overview, quick actions, charts, and budget highlights
- `Transactions`: full transaction history
- `Stats`: spending analytics, charts, and monthly budget summaries
- `Profile`: user stats, currency settings, converter, theme toggle, and account management

## Tech Stack

- Flutter
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Provider
- `fl_chart`
- `liquid_glass_renderer`

## Getting Started

### Prerequisites

- Flutter SDK `3.x+`
- A configured Firebase project
- Android Studio or Xcode for device builds

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

- Create a Firebase project
- Add your Android and iOS apps
- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/`

4. Configure environment variables for the currency converter:

Create a `.env` file in the project root with:

```env
API_KEY=your_exchange_rate_api_key
API_BASE=https://v6.exchangerate-api.com/v6/API_KEY/latest/
```

5. Run the app:

```bash
flutter run
```

## Downloads

You can download the latest release from the [Releases page](https://github.com/RobinNormy/BudgetBuddy/releases).

- `BudgetBuddy_Modern.apk` for newer ARM64 devices
- `BudgetBuddy_Legacy.apk` for older ARMv7 devices

## Project Structure

```text
lib/
├── main.dart
├── home_chart.dart
├── models/
├── screens/
│   ├── all_screens.dart
│   ├── home/
│   ├── input/
│   ├── intro/
│   ├── login/
│   ├── profile2/
│   ├── splash/
│   ├── stats_chats/
│   └── wallet/
├── services/
│   ├── auth.dart
│   ├── budget_service.dart
│   └── tutorial_service.dart
├── theme/
├── utils/
│   ├── budget_utils.dart
│   ├── category_utils.dart
│   ├── convertor.dart
│   ├── currency_utils.dart
│   ├── debouncer.dart
│   ├── stats.dart
│   └── streams.dart
└── widgets/
    ├── budget_widgets.dart
    ├── liquid_glass_nav_bar.dart
    ├── profile_reusablecards.dart
    └── reusable.dart
```

## Build

```bash
flutter build apk --release
```

For other targets:

```bash
flutter build ios --release
flutter build macos --release
flutter build linux --release
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
