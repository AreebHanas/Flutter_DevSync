# DevSync – Student Project & Task Tracker

A production-ready Flutter + Firebase application for tracking university coursework projects and tasks.

## Setup Instructions

### 1. Create a Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project (e.g. `devsync-app`)
3. Enable **Authentication** → **Email/Password** sign-in method
4. Enable **Cloud Firestore** → Create database in **production mode**

### 2. Configure FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This replaces `lib/firebase_options.dart` with your real credentials.

### 3. Install dependencies & run

```bash
flutter pub get
flutter run
```

### 4. Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /projects/{projectId} {
      allow read, update, delete: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
    }
    match /tasks/{taskId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Firestore Indexes

Create a composite index on `tasks`: `projectId ASC`, `dueDate ASC`
(Firebase will auto-prompt the first time you open the Deadlines screen).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
