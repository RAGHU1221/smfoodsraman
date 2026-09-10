# Sri Murugan Foods POS — Flutter App v3.0

## Features
- ✅ Offline billing (SQLite - works without internet)
- ☁️ Auto background sync when online
- 📱 Tamil + English support
- 🛒 Item search + category filter
- 💰 GST / Non-GST billing
- 💳 Multiple payment methods
- 📊 Dashboard + Reports
- 🗑️ Delete bills

## Build Steps

### Option 1: GitHub Actions (Automatic)
1. Push to GitHub → Actions tab → Build starts automatically
2. Download APK from Artifacts

### Option 2: Local (Flutter installed)
```bash
flutter pub get
flutter build apk --debug
# APK: build/app/outputs/flutter-apk/app-debug.apk
```

## Server Setup
Upload these files to InfinityFree:
- htdocs/api/mobile/login.php
- htdocs/api/mobile/items.php
- htdocs/api/mobile/save_bill.php
- htdocs/api/mobile/bills.php
- htdocs/api/mobile/dashboard.php
- htdocs/api/mobile/auth.php
