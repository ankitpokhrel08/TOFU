<div align="center">

<img src="assets/mascot/lift.png" width="140" alt="Tofu, the TOFU mascot"/>

# TOFU

**An AI personal trainer that fits in five minutes a day.**

TOFU watches each rep through your phone's camera, coaches your form by voice in real time,<br/>
and turns training into a game: 20 levels, stars, XP, streaks and a global leaderboard.

[![CI](https://github.com/ankitpokhrel08/gym-guru/actions/workflows/ci.yml/badge.svg)](https://github.com/ankitpokhrel08/gym-guru/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)

[Overview](#overview) · [Screenshots](#screenshots) · [Architecture](#architecture) · [Download](#download) · [Getting started](#getting-started) · [Roadmap](#roadmap)

</div>

<p align="center">
  <img src="docs/screenshots/05-get-ready.png" width="230" alt="Get ready with the exercise animation"/>
  &nbsp;&nbsp;
  <img src="docs/screenshots/07-tracking.png" width="230" alt="A tracked set"/>
  &nbsp;&nbsp;
  <img src="docs/screenshots/09-results.png" width="230" alt="Results"/>
</p>

## Overview

Most people quit training because sessions run long and nobody checks their form. TOFU keeps workouts short and gives feedback on every rep:

1. **Pick a level.** Each one is a short workout of 2–5 exercises with an animated demo of each move.
2. **Train in front of the camera.** Each exercise starts with an animated demo and a position check. On-device pose tracking then counts reps, times holds and flags form mistakes, with spoken cues.
3. **Level up.** Earn 1–3 stars, XP and achievements, keep your daily streak, and climb the weekly leaderboard.

### Features

| | |
| --- | --- |
| **Google sign-in** | Firebase Auth. Progress syncs across devices and works offline. |
| **Short setup** | Name and public nickname, one goal, daily minutes, experience and pain limitations. All editable later in Profile. |
| **6 tracked exercises** | Squat, push-up, plank, reverse lunge, glute bridge and jumping jacks, each with its own form checks. |
| **20 levels** | 4 units of 5, each ending in a boss level. New exercises arrive unit by unit, and experience sets where you start. |
| **Adapts to you** | Knee pain swaps lunges and jumping for bridges and eases squat depth; lower-back pain shortens planks. |
| **Recommendations** | Today offers your next level plus a drill aimed at your weakest exercise and most common mistake. |
| **Gamification** | Stars, XP, 6 ranks (Rookie → Legend), 9 achievements, a daily-goal ring, streaks with earned freezes, and rewards for unlocks and rank-ups. |
| **Leaderboard** | Weekly and all-time, top 50 plus your rank, shown by nickname only. |
| **Voice coaching** | Spoken cues for each new exercise and for form mistakes, rate-limited so it never chatters. Short original sounds for reps, countdown and level-ups. Both can be turned off. |
| **Help on demand** | A help button replays the exercise animation and pauses the set. |

> [!NOTE]
> Rep counting runs entirely on the device with Google ML Kit. Camera frames are never stored or uploaded. If the camera is unavailable or can't see you, the app offers a clearly labelled **demo set** that earns nothing.

## Screenshots

**Sign-in and setup**

<p>
  <img src="docs/screenshots/01-welcome.png" width="160" alt="Welcome and Google sign-in"/>
  <img src="docs/screenshots/02-goal.png" width="160" alt="Goal"/>
  <img src="docs/screenshots/03-plan.png" width="160" alt="Your plan"/>
  <img src="docs/screenshots/04-today.png" width="160" alt="Today"/>
</p>

**Training**

<p>
  <img src="docs/screenshots/05-get-ready.png" width="160" alt="Get ready"/>
  <img src="docs/screenshots/06-help.png" width="160" alt="Help sheet"/>
  <img src="docs/screenshots/07-tracking.png" width="160" alt="Tracked set"/>
  <img src="docs/screenshots/08-next-up.png" width="160" alt="Next exercise"/>
  <img src="docs/screenshots/09-results.png" width="160" alt="Results"/>
</p>

**Levels, ranks and profile**

<p>
  <img src="docs/screenshots/10-levels.png" width="160" alt="Levels"/>
  <img src="docs/screenshots/11-leaderboard.png" width="160" alt="Leaderboard"/>
  <img src="docs/screenshots/12-progress.png" width="160" alt="Progress and achievements"/>
  <img src="docs/screenshots/13-profile.png" width="160" alt="Profile"/>
</p>

## Architecture

### App flow

```mermaid
flowchart LR
    A[Welcome] -- "Google sign-in" --> B{Profile?}
    B -- "new user" --> C[Setup<br/>6 steps]
    B -- "returning" --> D[Main shell]
    C --> D
    D --- T1[Today]
    D --- T2[Levels]
    D --- T3[Leaderboard]
    D --- T4[Progress]
    T1 & T2 -- "Play" --> L[Workout intro]
    L --> K[Per exercise:<br/>demo → position check<br/>→ countdown → tracking]
    K --> W[Exercise 1 … n]
    W --> R[Results + rewards]
    R -- "Next level / Continue" --> D
```

### Code layout

```
lib/
├── main.dart                   Firebase init, fonts, portrait lock
├── app_root.dart               Sign-in → setup → main app routing
├── firebase_options.dart       Generated by FlutterFire (Android)
├── theme/app_theme.dart        Colour tokens, Baloo 2 / Nunito text styles
├── widgets/
│   ├── common.dart             Buttons, cards, headers, speech bubbles
│   ├── decor.dart              Painters and shapes (stripes, dashed outlines, week strip)
│   └── exercise_demo.dart      Looping Lottie demo for each exercise
├── game/
│   ├── exercises.dart          The 6 exercises, their cues and form issues
│   ├── levels.dart             The 20 levels, limitation adaptations, start levels
│   └── progression.dart        Stars, XP, ranks, achievements, drill recommendations
├── audio/
│   ├── coach.dart              Text-to-speech and sounds, with rate limits
│   └── workout_announcer.dart  Turns workout events into cues
├── data/
│   ├── models.dart             Profile, SessionResult, BlockResult (JSON)
│   ├── auth.dart               Google sign-in through Firebase Auth
│   └── repository.dart         Firestore: profile, sessions, leaderboard
├── tracking/
│   ├── tracker.dart            Workout lifecycle: intro → setup → countdown → workout, per exercise
│   ├── camera_tracker.dart     Front camera + ML Kit pose detection
│   ├── analyzers.dart          Per-exercise rep counting and form checks (pure Dart)
│   ├── simulated_tracker.dart  Scripted demo set
│   └── pose.dart               Joints and skeleton edges
├── onboarding/                 Setup flow and its screens
└── app/
    ├── main_shell.dart         Tabs and workout routing
    ├── app_controller.dart     Streaks, XP, stars, unlocks, freezes, rewards
    └── screens/                Today, levels, leaderboard, progress, profile, intro, camera, results, share
```

### Design decisions

- **One source of truth:** `AppController` derives streak, XP, stars, unlocks, achievements and the week strip from stored sessions instead of keeping separate counters.
- **Pose analysis:** each exercise has a pure-Dart analyzer working on 2D landmarks:
  - **Squats:** measured by how far the hips drop toward knee height, calibrated to the standing pose, which works facing the camera or side-on.
  - **Push-ups, lunges and bridges:** measured from joint angles.
  - **Plank:** graded in 5-second segments.
  - **Jumping jacks:** checked for full arm and leg range.
  
  The analyzers were validated on real Kaggle exercise videos (see `tool/video_eval`).
- **Setup gate:** before each exercise, counting starts only when the body is in frame, landmarks are confident and the user is still. Side-on exercises need just one full side visible.
- **Coaching without chatter:** speech only for a new exercise, a form mistake, "three more" and "can't see you". The same line repeats at most every 8 s, any two lines are 3.5 s apart, and frequent feedback (clean reps, countdown) is a sound instead.
- **Daily goal and streaks:** a day counts when active training time reaches the daily goal. Streak freezes (one per 500 XP, hold up to 2) cover a single missed day automatically.
- **Leaderboard integrity:** on Firebase's free plan the app writes its own totals, so Firestore security rules check every write. Only you can write your row, XP never decreases, and one write can add at most one workout's XP.
- **Offline-first:** Firestore's on-device cache keeps training working offline. Startup shows cached data immediately and refreshes from the server in the background.
- **Accessibility:** custom controls expose semantics, coaching cues are live regions, and animations show a still frame when the system's reduce-motion setting is on.

## Download

Get the latest APK from [Releases](../../releases/latest) and install it on an Android phone (allow installs from your browser when asked). Sign in with Google and you're ready to train.

## Getting started

### Requirements

| Tool | Version |
| --- | --- |
| Flutter | 3.47 (stable) |
| JDK | 17 or newer |
| Android SDK | API 36 |
| Firebase project | Free Spark plan is enough |

### Firebase setup

The repository doesn't include a Firebase config, so a clone runs on your own Firebase project:

1. Create a project in the [Firebase console](https://console.firebase.google.com) and add an Android app with package name `com.gymguru.gym_guru`.
2. Add your signing key's SHA-1 to that Android app (`cd android && ./gradlew signingReport` prints it), then enable **Google** under Authentication → Sign-in method.
3. Create a Firestore database.
4. Generate the config files, which are gitignored:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android
   ```

   This writes `lib/firebase_options.dart` and `android/app/google-services.json`. To fill them in by hand instead, start from `lib/firebase_options.example.dart`.
5. Deploy the security rules and indexes: `firebase use <your-project-id>`, then `firebase deploy --only firestore`.

### Run

```bash
git clone <this repository>
cd <repository folder>
flutter pub get
flutter run
```

Use a physical phone; emulator cameras rarely give a usable feed. Prop the phone at about hip height, 2–3 m away, so your whole body is in frame, and train in good light.

## Testing

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Tests don't need Firebase. Without your own config, copy the template first: `cp lib/firebase_options.example.dart lib/firebase_options.dart`.

| Suite | Covers |
| --- | --- |
| `analyzers_test.dart` | Rep counting and form checks for all 6 exercises, plus setup checks |
| `coach_test.dart` | Voice rate limits, mute settings, and which workout events speak or play sounds |
| `app_controller_test.dart` | Stars, XP, ranks, levels, drills, daily-goal streaks, freezes, demo sets not saved, profile edits |
| `app_flow_test.dart` | Sign-in, setup, a full level, leaderboard ranking, nickname edit, account deletion |
| `exercise_demo_test.dart` | Every animation loads, swaps cleanly and respects reduced motion |
| `firestore_config_test.dart` | Every leaderboard query has a deployed index; rules cover the app's collections |

The pose analyzers can also be checked against real workout videos: extract poses with MediaPipe and run `POSES=<dir> flutter test tool/video_eval`.

## Roadmap

- [x] On-device pose tracking for 6 exercises
- [x] Google sign-in, cloud sync and a global leaderboard
- [x] 20 levels with stars, XP, ranks, achievements and streaks
- [x] Voice coaching and sound effects
- [ ] Working share targets (Story, Message, Save)
- [ ] Server-validated leaderboard scores (Cloud Functions)
- [ ] iOS build
- [x] Custom app icon
- [ ] Launch screen

## Credits

Exercise animations from [LottieFiles](https://lottiefiles.com) under the Lottie Simple License; see [assets/exercises/CREDITS.md](assets/exercises/CREDITS.md). Sound effects were synthesised for this app.

## Author

Built by **Ankit Pokhrel** ([@ankitpokhrel08](https://github.com/ankitpokhrel08)).

## License

No license has been chosen yet, so all rights are reserved until one is added.
