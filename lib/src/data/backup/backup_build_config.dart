abstract final class BackupBuildConfig {
  /// Cloud UI stays absent from ordinary/test builds until OAuth registration
  /// has been provisioned for the actual application identity.
  static const bool googleDriveEnabled = bool.fromEnvironment(
    'GOOGLE_DRIVE_BACKUP_ENABLED',
    defaultValue: false,
  );
}
