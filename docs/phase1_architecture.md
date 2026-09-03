# EPS-TOPIK UBT System Architecture (Phase 1)

This document outlines the architecture for the EPS-TOPIK exam platform, ensuring it runs offline on both Android (SQLite) and Web (IndexedDB).

## 1. System Components
* **Admin Dashboard:** Web-based tool for teachers to upload questions, OCR PDFs, and manage audio.
* **Student App:** Flutter-based Android and Web (PWA) application for offline examination.
* **Cloud Backend:** Supabase or Firebase for user authentication, licenses, and package distribution.

## 2. Core Architecture
* **Frontend:** Flutter + Dart
* **Local Database:** Drift (SQLite for mobile, IndexedDB for Web)
* **Encryption:** AES-256-GCM for `.epstest` test packages.

## 3. Key Security Features
* **Audio Lock:** Listening audio plays twice and locks. Recovery preserves this state.
* **Anti-cheat:** Strict exam mode disables copy-paste, limits keyboard shortcuts, and logs tab switching.
* **Session Integrity:** Exam states are tracked second-by-second in the local database to survive crashes.
