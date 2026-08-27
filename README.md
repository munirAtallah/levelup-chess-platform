# LevelUp — Chess Teaching Platform

## Overview
A cross-platform app (web, iOS, Android) built with Flutter and Firebase for a chess-teaching non-profit in Jerusalem. The organization centrally manages instructional content, and instructors use it to teach chess to school students. Built by a four-person team where I served as team lead.

## Features
- Three user roles with separate interfaces: Admin, Instructor, Student
- Role-based authentication:
  - Admin / Instructor sign in with email + password
  - Students sign in with a simplified PIN-based login
- Curriculum repository for lessons, exercises, and training materials
- Assignment system with transaction-based grading
- Group management with support for multiple instructors and archiving
- Admin statistics dashboard and audit logs
- Full Arabic / English support with right-to-left (RTL) layout
- Secure backend: Firestore security rules, Cloud Functions for user management

## Tech Stack
`Flutter` · `Dart` · `Firebase` (Firestore · Cloud Functions · Auth)

## Usage
```bash
flutter pub get
flutter run
```
> Requires a Firebase project configured via `flutterfire configure`. The app targets web, iOS, and Android.

Live web app: https://edu.shah2range.com

## Team
- **Munir Atallah** — Team Lead
- **Ibrahim Al Hroub** — Team Member
- **Qais Hijazi** — Team Member
- **Ahmad Abu Gharbieh** — Team Member

## Notes
- Built for a real non-profit client as a final-year capstone project.
- The mobile app is named "LevelUp"; the organization brand is "شطرنج القدس" (Jerusalem Chess).
