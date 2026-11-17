# 🎉 Weekend Masti

> **Every Weekend Deserves a Story.**

Weekend Masti is a Flutter app that helps people discover, create and join real-world meetups around them: coffee, treks, cricket, cycling, food, music and more. It also has food ordering, group chat, friends, reviews and coupons.

The mobile app (Android) is the main client. An admin website shares the **same Firebase project and Firestore database**.

---

# 📱 Technology Stack

## App

- Flutter 3.44 / Dart 3.12
- Material 3 with a custom theme (`lib/app/theme/`)
- GetX for state management, dependency injection and navigation
- Google Fonts (Poppins) and the Fredoka font

## Backend (Firebase project `wekend-masti-c9bb4`)

- Firebase Authentication with phone OTP
- Cloud Firestore for all app data
- Firebase Storage for profile, banner and review photos
- Firebase Cloud Messaging for push notifications
- Cloud Functions (`functions/`, Node). **Not running at the moment**: the project is on the free Spark plan.

## Other packages

- `flutter_map` + `latlong2`: OpenStreetMap map, no API key needed
- `geolocator` for current location; Nominatim (`http`) for place search and city/address lookup
- `image_picker` for photos
- `speech_to_text` + `permission_handler` for voice search
- `razorpay_flutter` for payments (**test mode**, see below)
- `shared_preferences` for local session and settings
- `url_launcher`, `intl`, `flutter_svg`

---

# ✨ Features

- **Auth:** splash, onboarding, phone login, OTP, name entry, and an interests picker for new users
- **Home and Explore:** search (with voice), city filter, categories, upcoming meetup, premium banner
- **Meetups:**
  - create a meetup: map location picker, auto city, date/time, price, seats, private
  - meetup details, join requests and organizer approval, participants, My Meetups
- **Chat:** group chat per meetup, plus mute
- **Friends:** friend requests and a friends list
- **Notifications:** live list grouped by Today / Yesterday / This week / Earlier, mark all as read, swipe to delete, clear all
- **Food:** menu, cart, delivery address, order tracking, My Orders
- **Coupons:** My Coupons, and applying a coupon at checkout. Coupons are created and assigned from the admin website.
- **Reviews:** rate and review meetups
- **Profile:**
  - view and edit, profile photo, and interests (chips)
  - logout
- **Premium:** create meetups only with Premium, controlled by `app_config` (`premiumEnabled`)

---

# 🏗 Architecture

Feature-first, with a clean-architecture layer inside each feature:

```
lib/
├── app/
│   ├── bindings/        # initial GetX bindings
│   ├── routes/          # app_routes.dart (names) + app_pages.dart (GetPages)
│   └── theme/           # colors.dart, app_theme.dart
├── core/
│   ├── constants/       # AppSizes, AppTextStyles, ...
│   ├── services/        # location, geocoding, activity_logger
│   └── widgets/         # PrimaryButton, SectionTitle, EmptyState, AppLoader, ...
├── features/
│   ├── auth/            # splash, onboarding, login, OTP, name entry, interests
│   ├── home/            # home + choice screen
│   ├── experience/      # meetups: explore, details, create, my meetups, premium
│   ├── chat/
│   ├── friends/
│   ├── notifications/
│   ├── food/            # menu, cart, address, orders, Razorpay service
│   ├── coupons/
│   ├── reviews/
│   ├── profile/         # edit profile, interests picker widget
│   └── passport/
├── firebase_options.dart
└── main.dart
```

A feature usually has `controllers/`, `models/`, `repositories/`, `datasources/`, `screens/` and `widgets/`.

Data flows **Screen → Controller → Repository → Datasource → Firestore**.

---

# 🔐 App Flow

```
Splash
  ├─ first launch      → Onboarding → Login
  ├─ not logged in     → Login → OTP
  ├─ no name yet       → Name entry → (new users only) Interests → Choice
  └─ logged in         → Choice → Home / Explore / Food
```

- **Session:** login and onboarding status are kept in SharedPreferences.
- **On login:** the app writes `users/{uid}` with `isActive: true`, `lastSeenAt` and `fcmToken`.
- **On every app open:** Splash updates `users/{uid}.lastSeenAt` without waiting for it.
- **On logout:** the app sets `isActive: false`.

---

# ☁️ Firestore Collections

| Collection | Used for |
|---|---|
| `users` | profile (`name`, `bio`, `city`, `gender`, `photoUrl`, `interests`, `isActive`, `lastSeenAt`, `fcmToken`) |
| `meetups` | meetups (`participants`, `approvedMemberIds`, `joined`, `seats`, `createdBy`, ...) |
| `join_requests` | join requests (`pending` / `approved` / `rejected`) |
| `messages`, `chat_mutes` | group chat |
| `friend_requests` | friends |
| `notifications` | in-app notifications (index: `userId` ASC + `createdAt` DESC) |
| `reviews` | meetup reviews |
| `foodItems`, `orders` | food menu and orders |
| `coupons`, `user_coupons` | coupons (created by the admin website) |
| `activities` | activity log for the admin website (written by the app, best-effort) |
| `app_config` | app switches such as `premiumEnabled` |

**Shared with the admin website:**
- `users.interests`: a list of label strings, e.g. `["Concerts", "Food"]`.
- `activities` documents: `{ userId, userName, type, title, meetupId?, timestamp }`. `type` is one of `meetup_joined`, `event_joined`, `food_ordered`, `profile_updated` or `other`.

---

# ⚠️ Important Notes

- **Firestore rules:** the **live** rules in the Firebase Console are the source of truth, because the website adds rules for `coupons`, `user_coupons` and `mail`. **Do not deploy `firestore.rules` from this repo** without checking the live rules first.
- **New fields** such as `interests` and `lastSeenAt`, and the new `activities` writes, need the live rules to allow them.
- **Cloud Functions:** they don't run on the Spark plan. Because of that, the app marks coupons as used itself, right after an order is saved.
- **Payments:**
  - Food orders use test mode (`_dummyPaymentMode = true` in `food_menu_controller.dart`).
  - The Razorpay keys are placeholders.
  - Premium status is stored only on the device for now.
- **Secrets:** never commit real API secrets or passwords. Firebase client config in `firebase_options.dart` is public by design.

---

# 🛠 Getting Started

```bash
flutter pub get
flutter run                      # run on a connected device
flutter analyze                  # static checks
flutter build apk --release      # Android build
```

- **Requirements:** the Flutter SDK, Android Studio or the Android SDK, and access to the Firebase project.
- **App icons** are generated with `dart run flutter_launcher_icons` (config in `pubspec.yaml`).
- **Web:** the `web/` folder exists, but the web build isn't supported yet (phone OTP, Razorpay and voice search are mobile-only).

---

# 🎨 Design System

- 🟧 Primary: Orange `#FF5A3D`
- 🟫 Text / dark: Dark Brown `#2B1D1A`
- 🤍 Background: Warm Cream `#FFF8EC`
- **Fonts:** Poppins (UI) and Fredoka (brand)
- **Colors and styles:** always use `AppColors`, `AppSizes` and `AppTextStyles`. Don't hard-code new colors.

---

# 🛣 Roadmap

**Done**
- Auth and onboarding
- Home and Explore
- Create Meetup with a map picker
- Join requests and approval
- My Meetups
- Group chat
- Friends
- In-app and push notifications
- Reviews
- Food ordering (test payments)
- Coupons
- Interests

**Next**
- Real Razorpay payments, verified by a server (needs the Blaze plan / Cloud Functions)
- Premium stored in Firestore with an expiry
- Admin blocking (`isBlocked`)
- Web version at `/app` with guest browsing and Google sign-in
- Release signing, performance and testing, then the Play Store release

---

# 💻 Development Guidelines

- Follow the feature-first structure, and keep business logic out of widgets.
- Use GetX for state and navigation, and reuse the widgets in `core/widgets`.
- Change only the files a task needs, and keep existing flows working.
- Run `flutter analyze` before committing, and write clear commit messages.

---

# 📜 License

Private project under active development.

**© Weekend Masti. All Rights Reserved.**
