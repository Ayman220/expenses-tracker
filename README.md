# 💸 Expense Tracker App

A Flutter + Firebase-powered mobile app to track group expenses, split bills, and simplify debts. Designed as a showcase project demonstrating clean architecture, modern Flutter practices, and real-time state management using **GetX**.

---

## 🚀 Features

### 🔐 Authentication
- Email/Password login and registration
- Email verification flow with cooldown resend logic
- Password reset via email
- Logout with reactive auth state

### 💰 Expense Management
- Create groups and track shared expenses
- Add and settle expenses between members
- Calculate who owes whom
- Simplify group debts with a single tap

### 📡 Realtime Integration
- Firebase Authentication and Firestore
- Auth and email verification state managed via streams
- Group data synced in real-time across devices

### 💡 UI & Experience
- Responsive layout and smooth navigation
- Pull-to-refresh in group details
- Custom themes and consistent padding/icons
- Email resend cooldown timer
- Reactive loading and state updates via GetX

---

## ⚙️ Tech Stack

| Category         | Tools                            |
|------------------|----------------------------------|
| UI Framework     | Flutter                          |
| State Management | GetX                             |
| Backend          | Firebase Auth, Firestore         |
| Utils            | Snackbars, Validation, Custom UI |

---

## 🧑‍💻 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/expense_tracker.git
cd expense_tracker
```
### 2. Install Dependencies
```bash
flutter pub get
```
🔥 Firebase Setup
1- Create a Firebase Project
    * Go to Firebase Console
    * Create a new project and add an Android/iOS app
    * Enable Services
    * Enable Email/Password Authentication
    * Enable Cloud Firestore in test mode

2- Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```
Configure FlutterFire in your project From the root of your project, run:
```bash
flutterfire configure
```
This will generate the required lib/firebase_options.dart file and set up your platforms.
Run the App
```bash
flutter run
```

### Project Structure
```bash
lib/
├── controllers/           # GetX Controllers
├── helpers/               # Snackbars and utilities
├── models/                # Custom User, Group, Expense, Settlement models
├── screens/
│   ├── authentication/    # Login, Register, Verify Email, Reset Password
│   ├── home/              # Home, Groups
│   ├── groups/              # Group details, expenses, balances, settlements
├── services/              # Firebase Auth & Firestore logic
├── theme/                 # Custom theme and styles
└── main.dart
```
🔁 Authentication Flow
User signs up → Verification email sent

Unverified users see a Verify Email screen with cooldown

App listens to FirebaseAuth.userChanges() and updates UI automatically

Logout resets both Firebase and custom app state

📌 To-Do & Future Improvements
 Push notifications (e.g., expense added)

 Group invites via link or email

 Export summary as PDF/CSV

 User avatars and profile customization

 Group chat/comments

📃 License
MIT License