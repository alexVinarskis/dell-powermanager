import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cctk_state.dart';
import 'cctk.dart';

/// Abstraction for BIOS read/write: CCTK (Dell Command | Configure) or DellBIOSProvider (PowerShell).
abstract class BiosBackend {
  /// Ensure the backend is ready (deps installed). For DellBIOSProvider may run prerequisites and Install-Module.
  Future<bool> ensureReady();

  /// Update [cctkState] with current values for [queryParams]. Returns true on success.
  Future<bool> query(List<dynamic> queryParams, CCTKState cctkState, SharedPreferences? prefs);

  /// Set BIOS attribute [cctkType] to [mode]. Updates [cctkState].exitStateWrite. Returns true on success.
  Future<bool> request(String cctkType, String mode, CCTKState cctkState, {String? requestCode});

  /// Apply environment (e.g. BIOS password) to [shell] for subprocess calls.
  void sourceEnvironment(Shell shell);
}
