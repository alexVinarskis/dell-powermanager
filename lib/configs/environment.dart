class Environment {
  static bool runningDebug = false;
  static String? biosPwd;
  /// When true (e.g. --use-cctk passed), force use of Dell Command | Configure (CCTK) on Windows instead of DellBIOSProvider.
  static bool useCctk = false;
}
