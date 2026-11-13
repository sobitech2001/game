# STAR DODGE - GitHub Android build

This repository contains the Godot 4 prototype and a GitHub Actions workflow that builds a debug APK.

## Build an APK with GitHub

1. Create a new **public or private** repository on GitHub.
2. Upload the contents of this folder to the repository root. Make sure `.github/workflows/android.yml` is included.
3. Open the repository's **Actions** tab.
4. Select **Build Android APK**.
5. Press **Run workflow** (or push a commit to `main` to trigger it).
6. When the workflow finishes, open its run page and download the artifact named **StarDodge-Android-APK**.
7. Extract the artifact ZIP and install `StarDodge-debug.apk` on an Android 10+ device. If Android blocks installation, allow installing apps from that browser/file manager.

## Important
- This is a **debug APK** for testing, not a Play Store release.
- The APK is configured for ARM64 Android devices.
- The workflow installs Godot 4.3, its matching Android export templates, Java 17, and the Android SDK packages required by Godot 4.3.
- The workflow uses `android-actions/setup-android@v4`; it does not request the removed standalone Android SDK `tools` package.
- For a Play Store release, configure a private signing keystore and use GitHub Actions secrets. Never commit your keystore or passwords.

## Controls
Touch and drag horizontally to steer. Tap to start and tap after game over to restart.
