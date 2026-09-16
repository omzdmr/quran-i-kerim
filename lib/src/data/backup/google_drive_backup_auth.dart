import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'backup_cloud_connector.dart';
import 'google_drive_app_data_backup_store.dart';

class GoogleDriveBackupAuthorizationRequired implements Exception {
  const GoogleDriveBackupAuthorizationRequired();

  @override
  String toString() => 'Google Drive authorization requires user interaction.';
}

class GoogleDriveBackupUnsupported implements Exception {
  const GoogleDriveBackupUnsupported();

  @override
  String toString() => 'Interactive Google sign-in is unsupported on this platform.';
}

/// Creates an authenticated Drive backup connection on demand.
///
/// No Google account is requested during app startup. The UI calls [connect]
/// from an explicit user action, and only the appDataFolder scope is requested.
/// Android builds may provide a web OAuth client through
/// `--dart-define=GOOGLE_DRIVE_SERVER_CLIENT_ID=...`; a future iOS build can
/// provide its platform client through `GOOGLE_DRIVE_CLIENT_ID`.
class GoogleDriveBackupAuth implements BackupCloudConnector {
  GoogleDriveBackupAuth({
    GoogleSignIn? signIn,
    String? clientId,
    String? serverClientId,
  }) : signIn = signIn ?? GoogleSignIn.instance,
       clientId = clientId ??
           const String.fromEnvironment('GOOGLE_DRIVE_CLIENT_ID'),
       serverClientId = serverClientId ??
           const String.fromEnvironment('GOOGLE_DRIVE_SERVER_CLIENT_ID');

  static const List<String> scopes = <String>[
    drive.DriveApi.driveAppdataScope,
  ];

  final GoogleSignIn signIn;
  final String clientId;
  final String serverClientId;

  Future<void>? _initialization;

  Future<void> initialize() {
    return _initialization ??= signIn.initialize(
      clientId: clientId.trim().isEmpty ? null : clientId.trim(),
      serverClientId:
          serverClientId.trim().isEmpty ? null : serverClientId.trim(),
    );
  }

  @override
  Future<BackupCloudConnection> connect({bool interactive = true}) async {
    await initialize();

    GoogleSignInAccount? account;
    final lightweight = signIn.attemptLightweightAuthentication();
    if (lightweight != null) {
      account = await lightweight;
    }

    if (account == null) {
      if (!interactive) {
        throw const GoogleDriveBackupAuthorizationRequired();
      }
      if (!signIn.supportsAuthenticate()) {
        throw const GoogleDriveBackupUnsupported();
      }
      account = await signIn.authenticate(scopeHint: scopes);
    }

    var authorization = await account.authorizationClient
        .authorizationForScopes(scopes);
    if (authorization == null) {
      if (!interactive) {
        throw const GoogleDriveBackupAuthorizationRequired();
      }
      authorization = await account.authorizationClient.authorizeScopes(scopes);
    }

    final client = authorization.authClient(scopes: scopes);
    final api = drive.DriveApi(client);
    return BackupCloudConnection(
      accountLabel: account.email,
      store: GoogleDriveAppDataBackupStore(api),
      close: client.close,
    );
  }

  @override
  Future<void> signOut() async {
    await initialize();
    await signIn.signOut();
  }

  Future<void> disconnect() async {
    await initialize();
    await signIn.disconnect();
  }
}
