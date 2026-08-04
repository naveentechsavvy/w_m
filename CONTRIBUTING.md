# Weekend Masti Architecture

## Architecture Style

Feature First + Clean Architecture

## Technology Stack

Frontend

- Flutter
- Dart
- Material 3
- GetX

Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Storage

---

## Folder Structure

```
lib/

app/
    bindings/
    routes/
    theme/

core/
    widgets/
    constants/
    utils/
    services/

features/

    auth/

    experience/

    profile/

    home/

    passport/

    food/
```

---

## Feature Structure

Each feature contains:

```
feature/

controllers/

datasources/

repositories/

models/

widgets/

screens/
```

---

## State Management

Use GetX.

Business Logic

Controller

Database

Repository

Firebase Calls

Datasource

UI

Widgets + Screens

---

## Firebase Collections

```
users

meetups

join_requests

messages

notifications

reviews

categories
```

---

## Session

SharedPreferences

Keys

```
is_logged_in

profile_completed

onboarding_completed

phone_number
```

---

## UI Principles

- Responsive
- Modular
- Reusable
- Minimal
- Premium
- Material 3

Never duplicate widgets.

Never redesign architecture.
