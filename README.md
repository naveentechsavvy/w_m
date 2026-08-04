# 🎉 Weekend Masti

> **Every Weekend Deserves a Story.**

Weekend Masti is a modern Flutter application designed to help people discover, create, and join real-world experiences happening around them. The platform focuses on bringing communities together through activities, hobbies, sports, travel, food, networking, and social events.

The goal is to build a scalable, production-ready social meetup platform with a premium user experience.

---

# 🚀 Vision

Weekend Masti aims to become a one-stop platform for people to connect through shared interests and experiences.

Users can:

- ☕ Join Coffee Meetups
- 🥾 Explore Weekend Treks
- 🏏 Participate in Cricket Matches
- 🚴 Join Cycling Groups
- 🍔 Discover Food Walks
- 🎵 Attend Music Events
- 💼 Network with Professionals
- ✈️ Plan Travel Experiences
- 🎮 Join Gaming Communities
- 🎨 Attend Workshops & Hobby Clubs

---

# 📱 Technology Stack

## Frontend

- Flutter (Latest Stable)
- Dart
- Material 3
- GetX

## Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Storage

## Planned Integrations

- Firebase Cloud Messaging
- Google Maps
- Razorpay
- Firebase Analytics

---

# 🏗 Architecture

The application follows **Feature First + Clean Architecture**.

```
lib/

├── app/
│   ├── bindings/
│   ├── routes/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── widgets/
│   ├── services/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── profile/
│   ├── experience/
│   ├── home/
│   ├── notifications/
│   ├── chat/
│   ├── meetup/
│   ├── passport/
│   └── food/
│
├── firebase_options.dart
└── main.dart
```

Each feature is self-contained with its own:

- Controllers
- Models
- Repositories
- Datasources
- Widgets
- Screens

---

# 🎨 Design System

## Brand

**Weekend Masti**

## Theme

- 🟧 Primary – Orange
- 🟫 Secondary – Dark Brown
- 🤍 Background – Warm Cream

## UI Principles

- Modern
- Minimal
- Premium
- Responsive
- Reusable Components
- Material 3
- Clean User Experience

---

# 📂 Assets Structure

```
assets/

├── avatars/
├── banners/
├── experiences/
├── icons/
├── illustrations/
└── logos/
```

---

# 🔐 Authentication Flow

```
Splash

↓

Onboarding

↓

Phone Login

↓

OTP Verification

↓

Profile Completion

↓

Home Dashboard
```

User session is managed using **SharedPreferences**.

---

# ☁️ Firestore Collections

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

# 📌 Current Project Status

## ✅ Completed

### Foundation

- Flutter Project Setup
- Firebase Configuration
- GetX Integration
- Feature-first Folder Structure

### Authentication

- Splash Screen
- Onboarding
- Phone Login
- OTP Verification
- Firebase Authentication
- Session Management
- Profile Completion

### UI

- App Theme
- Brand Colors
- Explore Screen
- Experience Card
- Dummy Experience Data

---

## 🚧 In Progress

- Home Dashboard
- Bottom Navigation
- Branding
- Image Assets
- Logout
- Notifications
- Experience Improvements

---

# 🛣 Roadmap

## Sprint 1 ✅

- Project Setup
- Authentication
- Splash Screen
- OTP Login
- Profile Completion
- Theme

---

## Sprint 2 🚧

- Home Dashboard
- Bottom Navigation
- Categories
- Trending Experiences
- Nearby Experiences
- Recommended Experiences
- Branding
- Image Assets
- Logout

---

## Sprint 3

- Create Meetup
- Firebase Storage Upload
- Firestore Integration
- Meetup Form

---

## Sprint 4

- Explore
- Search
- Category Filters
- Nearby Meetups
- Firestore Data

---

## Sprint 5

- Experience Details
- Gallery
- Organizer Profile
- Join Meetup

---

## Sprint 6

- Join Request Workflow
- Organizer Approval
- Request Status

---

## Sprint 7

- My Meetups
- Upcoming
- Joined
- Created
- Completed

---

## Sprint 8

- Chat
- Group Chat
- Organizer Chat

---

## Sprint 9

- Push Notifications
- Join Request Updates
- Meetup Reminders

---

## Sprint 10

- Google Maps
- Nearby Experiences
- Directions
- Location Picker

---

## Sprint 11

- Reviews & Ratings
- Photo Sharing
- Experience Feedback

---

## Sprint 12

- Payments
- Razorpay Integration
- Paid Meetups

---

## Sprint 13

- Performance Optimization
- Offline Support
- Testing
- Play Store Release

---

# 💻 Development Guidelines

All contributors should follow these principles:

- Follow Feature First Architecture.
- Keep business logic outside UI.
- Use GetX for state management and navigation.
- Reuse widgets whenever possible.
- Avoid duplicate code.
- Keep widgets modular.
- Use AppColors, AppSizes, AppTextStyles and AppAssets.
- Do not modify unrelated files.
- Preserve the existing folder structure.
- Provide production-ready implementations.

---

# 🤝 Contributing

Before implementing any feature:

1. Understand the current implementation.
2. Preserve the architecture.
3. Modify only the required files.
4. Reuse existing widgets.
5. Test your changes before committing.
6. Write meaningful commit messages.

---

# 📄 Project Documentation

Project documentation is maintained in:

- README.md
- ARCHITECTURE.md
- PROJECT_STATUS.md
- CHANGELOG.md

---

# 📜 License

This project is currently under active private development.

**© Weekend Masti. All Rights Reserved.**
