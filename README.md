# Sri Murugan Foods POS — Android App (Complete Project v2.2)

Full Android Studio project. Wraps the live POS site in a native WebView app with:
offline fallback page, swipe-to-refresh, file uploads, external link handling
(tel/mailto/WhatsApp/UPI), server file downloads via DownloadManager, and a
**JS bridge that saves jsPDF `blob:` downloads** (bills/exports) to the phone —
plain WebView cannot do this, so this is required for the POS PDF billing.

---

## ⚠️ ONE required change before building

Open `app/src/main/java/com/srimuruganfoods/pos/MainActivity.java` and set your
live URL (line ~44):

```java
private static final String APP_URL = "https://YOUR-SUBDOMAIN.infinityfreeapp.com/";
```

---

## Method 1 — GitHub Actions cloud build (NO Android Studio needed)

1. Create a new GitHub repository (private is fine).
2. Upload this entire folder's contents to the repo (drag-and-drop on github.com
   works, or `git push`). The workflow file `.github/workflows/build-apk.yml`
   is already included.
3. Go to the repo → **Actions** tab → the "Build Signed APK" workflow runs
   automatically on push (or press **Run workflow**).
4. After ~3–5 minutes, open the finished run → **Artifacts** →
   download `SriMuruganPOS-release-apk` → inside is `app-release.apk`.
5. Copy to phone and install. Done — signed, installable, shrunk with R8.

Every future push rebuilds the APK automatically.

## Method 2 — Android Studio local build

1. Android Studio (Hedgehog or newer) → **Open** → select this folder.
2. Let Gradle sync (it downloads Gradle 8.7 + AGP 8.5.2 automatically).
3. **Build → Build App Bundle(s) / APK(s) → Build APK(s)**.
4. APK lands in `app/build/outputs/apk/release/app-release.apk`
   (release is pre-signed — no "Generate Signed APK" wizard needed).

---

## Signing keystore (already configured in `app/build.gradle`)

| Field          | Value                       |
|----------------|-----------------------------|
| File           | `smfoods-release.keystore`  |
| Alias          | `smfoods`                   |
| Store password | `smfoods2026`               |
| Key password   | `smfoods2026`               |
| Validity       | 30 years                    |

**Back this file up.** All future updates of the app must be signed with the
same keystore, otherwise Android will refuse to update over the old install.
If the repo is public, move the keystore out and use GitHub Secrets instead.

## Notes

- `minSdk 24` → works on Android 7.0+.
- `usesCleartextTraffic="true"` kept for InfinityFree http fallback; remove
  once the site is https-only.
- App icons were generated from `assets/images/icon-512.png` of the web app.
- `offline.html` from the web app is bundled as the no-internet screen.
- IndexedDB / localStorage / Service Worker (PWA offline billing) all work
  inside the WebView since DOM storage is enabled.
