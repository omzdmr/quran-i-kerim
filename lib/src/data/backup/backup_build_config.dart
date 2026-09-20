abstract final class BackupBuildConfig {
  /// Cloud backup is opt-in at build time. Ordinary/test push builds keep the
  /// feature absent until a real OAuth registration is intentionally supplied.
  static const bool googleDriveRequested = bool.fromEnvironment(
    'GOOGLE_DRIVE_BACKUP_ENABLED',
    defaultValue: false,
  );

  /// Android uses the Web OAuth client ID as google_sign_in's serverClientId
  /// when google-services.json is not part of the build.
  static const String googleDriveServerClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_SERVER_CLIENT_ID',
  );

  /// Reserved for the future iOS/macOS application client configuration.
  static const String googleDriveClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_CLIENT_ID',
  );

  /// The repository currently produces Android APKs without google-services.json,
  /// so enabling the UI without a Web OAuth client ID would only expose a button
  /// that can never authenticate.
  static bool get googleDriveEnabled =>
      googleDriveRequested && googleDriveServerClientId.trim().isNotEmpty;

  static bool get googleDriveMisconfigured =>
      googleDriveRequested && !googleDriveEnabled;
}
