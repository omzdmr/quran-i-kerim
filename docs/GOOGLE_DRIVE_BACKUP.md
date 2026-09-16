# Google Drive Backup Setup

The application keeps Google Drive backup disabled in ordinary builds. Drive backup is enabled only for an intentionally configured build and uses the hidden `appDataFolder` space with the `drive.appdata` scope.

## Google Cloud configuration

1. Create or select a Google Cloud project.
2. Enable **Google Drive API**.
3. Configure the OAuth consent screen for the application.
4. Create an **Android OAuth client** for the APK identity:
   - Package name: `com.omzdmr.quran_i_kerim`
   - SHA-1: use the value printed by the `Verify stable test signing certificate` GitHub Actions step for test APKs.
5. Create a **Web application OAuth client** in the same Google Cloud project.
6. Use the Web OAuth client ID as `GOOGLE_DRIVE_SERVER_CLIENT_ID` when building Android. The client ID is not a secret. Do not commit or embed a client secret.

Production/release signing uses a different certificate from the repository's non-production test key. Register the production package/signing SHA-1 as a separate Android OAuth client before distributing a production build.

## Build locally

```bash
flutter build apk \
  --release \
  --target-platform android-arm64 \
  --dart-define=GOOGLE_DRIVE_BACKUP_ENABLED=true \
  --dart-define=GOOGLE_DRIVE_SERVER_CLIENT_ID="YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com"
```

If `GOOGLE_DRIVE_BACKUP_ENABLED=true` is supplied without a non-empty server client ID, the Drive UI remains hidden rather than exposing a sign-in action that cannot work.

## Build through GitHub Actions

Run the **Android APK** workflow manually and provide the optional `google_drive_server_client_id` input. The workflow validates that the value looks like a Google OAuth Web client ID and adds the two required Dart defines only for that manually triggered build.

Normal push builds do not enable Drive backup.

## Privacy and data scope

The Drive integration requests only:

`https://www.googleapis.com/auth/drive.appdata`

This scope stores application-owned configuration data in the user's hidden Drive application-data folder. It does not grant the app general access to the user's normal Drive files.

The backup manifest still excludes exact location/coordinates, downloaded Quran/translation packages, audio cache, and memorization voice recordings.

## Device test checklist

For a Drive-enabled test APK:

1. Connect a Google account from Backup settings.
2. Create the first cloud backup.
3. Change local reader/progress/preferences data.
4. Refresh and confirm the app reports a divergence instead of silently overwriting either side.
5. Test both explicit choices: upload this device and restore from Drive.
6. Restart the app and confirm lightweight authentication reconnects without requesting an account at startup.
7. Sign out and confirm cloud state is cleared while local data remains intact.
8. Repeat with a second device/install before production release.
