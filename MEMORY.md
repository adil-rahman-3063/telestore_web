# TeleStore - Project Memory

## 🚀 Project Overview
TeleStore is a custom personal cloud storage application (similar to Google Drive/Dropbox) that leverages **Telegram as an unlimited, free storage backend** and **Supabase (PostgreSQL)** for database metadata. 

The project has three main codebases:
1. **Backend:** `telestore-backend` (FastAPI)
2. **Mobile Frontend:** `telestore` (Flutter mobile-focused app)
3. **Web/Responsive Frontend:** `telestore_web` (Flutter web-focused app optimized for both mobile and web viewports)

---

## 🛠️ Architecture & Tech Stack

### Backend (`telestore-backend`)
- **Framework:** FastAPI (Python)
- **Database:** Supabase (PostgreSQL) - Tracks users, folders, and files. (SQLite is only used internally by Telethon for session management).
- **Storage Client:** `Telethon` - Uploads/downloads media silently via a Telegram channel.
- **Authentication:** Telegram OTP-based login.

**Key Endpoints:**
- `POST /auth/send-code`: Sends OTP via Telegram.
- `POST /auth/verify-code`: Verifies OTP and returns `user_id`.
- `POST /auth/set-channel`: Sets the Telegram channel ID for file storage.
- `GET/POST/PUT/DELETE /folders/...`: CRUD operations for folders (boards).
- `GET/POST/PUT/DELETE /files/...`: File operations (uploading chunks metadata).

### Frontend Apps (`telestore` & `telestore_web`)
- **Framework:** Flutter (Dart)
- **State/Network:** `http` for API calls, `shared_preferences` for session storage.
- **Design System:** 
  - Glassmorphic UI featuring `GlassContainer` widgets for frosted-glass visuals.
  - **Colors:** `AppColors.primary` (Modern Vibrant Blue), `AppColors.grey900`, etc.
  - **Typography:** `GoogleFonts.poppins` used globally.
  - **Custom MainScaffold:** Floating glassmorphic navigation bar (vertical swipe/tap between Home and Profile).

---

## 🚦 Current Status & Roadmap

### ✅ Completed
1. **New Project Setup:** Created `telestore_web` supporting all platforms (Web, Android, iOS, Windows, macOS, Linux).
2. **Asset Syncing:** Replicated all assets and dependencies from `telestore` to `telestore_web`.
3. **Compilation Fixes:** Resolved syntax/compilation issues in `home_screen.dart` (restored missing closing parentheses on `GlassContainer`).
4. **Code Porting:** Ported all lib files successfully from `telestore` to `telestore_web`.

### 🚧 Next Steps (To Be Implemented)
- **Step 1: Layout Responsiveness**
  - Adjust grid layouts in `home_screen.dart` to use responsive layout builders, ensuring correct grid column count on wide monitors vs mobile screens.
- **Step 2: File Uploading**
  - Implement file selection via `file_picker` and upload functionality to backend `/upload` route.
- **Step 3: Folder Navigation**
  - Allow users to tap and enter subfolders.
- **Step 4: File Interactions**
  - Implement download, delete, rename, and preview logic.
