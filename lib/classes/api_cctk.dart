import 'dart:async';
import 'dart:io';
import 'package:dell_powermanager/classes/bios_protection_manager.dart';
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../configs/constants.dart';
import '../classes/cctk_state.dart';
import '../classes/cctk.dart';
import '../classes/bios_backend.dart';
import '../classes/cctk_backend.dart';
import '../classes/dell_bios_provider_backend.dart';
import '../configs/environment.dart';

class ApiCCTK {
  static final List _initialQueryParameters = [CCTK.thermalManagement, CCTK.primaryBattChargeCfg];
  static final List _additionalQueryParameters = [];
  static List _queryParameters = _initialQueryParameters;
  static void addQueryParameter(var parameter) {
    _additionalQueryParameters.add(parameter);
    _queryParameters = {..._initialQueryParameters, ..._additionalQueryParameters}.toList();
  }
  static void removeQueryParameter(var parameter) {
    _additionalQueryParameters.remove(parameter);
    _queryParameters = {..._initialQueryParameters, ..._additionalQueryParameters}.toList();
  }

  static final List<Function(bool apiReady)> _callbacksDepsChanged = [];
  static void addCallbacksDepsChanged(var callback)  { _callbacksDepsChanged.add(callback); }
  static void removeCallbacksDepsChanged(var callback) { _callbacksDepsChanged.remove(callback); }

  static final List<Function(CCTKState cctkState)> _callbacksStateChanged = [];
  static void addCallbacksStateChanged(var callback)  { _callbacksStateChanged.add(callback); }
  static void removeCallbacksStateChanged(var callback) { _callbacksStateChanged.remove(callback); }

  static late Duration _refreshInternal;
  static late Timer _timer;
  static bool? _apiReady;
  static bool _cctkLockHeld = false;
  static final List<Completer<void>> _cctkWaitQueue = [];
  static Shell _shell = Shell();

  static SharedPreferences? _prefs;
  static const _uuid = Uuid();

  static final CCTKState cctkState = CCTKState();
  static BiosBackend? _backend;
  static bool _dellBiosProviderAttemptedAndFailed = false;

  /// True when the Missing Dependencies warning should be shown: Linux or --use-cctk (CCTK required), or Windows default and DellBIOSProvider failed.
  static bool _shouldShowDepsWarning() =>
      Platform.isLinux ||
      Environment.useCctk ||
      (Platform.isWindows && !Environment.useCctk && _dellBiosProviderAttemptedAndFailed);

  /// Selects backend: Linux or --use-cctk -> CctkBackend; Windows -> try DellBIOSProvider then CctkBackend.
  static Future<BiosBackend> _getOrCreateBackend() async {
    if (_backend != null) return _backend!;
    if (Platform.isLinux || Environment.useCctk) {
      _backend = CctkBackend(_shell);
      return _backend!;
    }
    if (Platform.isWindows) {
      final dp = DellBiosProviderBackend(_shell);
      if (await dp.ensureReady()) {
        _backend = dp;
        return _backend!;
      }
      _dellBiosProviderAttemptedAndFailed = true;
    }
    _backend = CctkBackend(_shell);
    return _backend!;
  }

  ApiCCTK(Duration refreshInternal) {
    sourceEnvironment();
    BiosProtectionManager.secureReadPassword();
    _refreshInternal = refreshInternal;
    _query();
    _timer = Timer.periodic(_refreshInternal, (Timer t) => _query());
  }
  static void requestUpdate() {
    _timer.cancel();
    _query();
    _timer = Timer.periodic(_refreshInternal, (Timer t) => _query());
  }
  static void stop() {
    _timer.cancel();
  }
  static void sourceEnvironment() {
    _shell = Shell(
      verbose: Environment.runningDebug,
      throwOnError: false,
      environment: Environment.biosPwd == null ? null : (ShellEnvironment()..vars[Constants.varnameBiosPwd] = Environment.biosPwd!),
    );
    _backend?.sourceEnvironment(_shell);
  }

  static void _callDepsChanged(bool apiReady) {
    final dubList = List<Function(bool)>.from(_callbacksDepsChanged);
    for (final callback in dubList) callback(apiReady);
  }
  static void _callStateChanged(CCTKState state) {
    final dubList = List<Function(CCTKState)>.from(_callbacksStateChanged);
    for (final callback in dubList) callback(state);
  }

  /// Acquire the backend mutex (waits if _query() or another request() is running).
  /// Uses a queue of completers so only one caller holds the lock at a time; no race when multiple callers await concurrently.
  static Future<void> _cctkAcquire() async {
    final completer = Completer<void>();
    _cctkWaitQueue.add(completer);
    if (!_cctkLockHeld) {
      _cctkLockHeld = true;
      _cctkWaitQueue.remove(completer);
      return;
    }
    await completer.future;
  }

  /// Release the backend mutex; unblocks the next waiter if any.
  static void _cctkReleaseMutex() {
    if (_cctkWaitQueue.isNotEmpty) {
      _cctkWaitQueue.removeAt(0).complete();
    } else {
      _cctkLockHeld = false;
    }
  }

  static Future<bool> _query() async {
    if (cctkState.cctkCompatible == false) return false;

    await _cctkAcquire();
    try {
      final backend = await _getOrCreateBackend();
      if (!(_apiReady ?? true)) {
        _apiReady = await backend
            .ensureReady()
            .timeout(Duration(seconds: Constants.backendEnsureReadyTimeoutSec), onTimeout: () => throw TimeoutException('ensureReady'));
        if (_apiReady!) {
          _callDepsChanged(true);
        } else if (_shouldShowDepsWarning()) {
          _callDepsChanged(false);
        }
        if (!(_apiReady ?? false)) return false;
      }

      _prefs ??= await SharedPreferences.getInstance();
      final success = await backend
          .query(List.from(_queryParameters), cctkState, _prefs)
          .timeout(Duration(seconds: Constants.backendQueryTimeoutSec), onTimeout: () => throw TimeoutException('query'));
      if (!success) {
        // Mark not ready so next _query() re-runs ensureReady() (recovery from transient backend/BIOS failure).
        _apiReady = false;
        if (_shouldShowDepsWarning()) _callDepsChanged(false);
      } else {
        _apiReady = true;
        _callDepsChanged(true);
      }
      _callStateChanged(cctkState);
      return success;
    } catch (_) {
      // Transient failure (e.g. timeout, IO): mark not ready so next _query() re-runs ensureReady().
      _apiReady = false;
      if (_shouldShowDepsWarning()) _callDepsChanged(false);
      _callStateChanged(cctkState);
      return false;
    } finally {
      _cctkReleaseMutex();
    }
  }

  static Future<bool> request(String cctkType, String mode, {String? requestCode}) async {
    await _cctkAcquire();
    try {
      final backend = await _getOrCreateBackend();
      final success = await backend
          .request(cctkType, mode, cctkState, requestCode: requestCode ?? _uuid.v4())
          .timeout(Duration(seconds: Constants.backendRequestTimeoutSec), onTimeout: () => throw TimeoutException('request'));
      if (!success) {
        _apiReady = false;
        if (_shouldShowDepsWarning()) _callDepsChanged(false);
      } else {
        _callDepsChanged(true);
        // Reflect written value in state so UI stays in sync without waiting for next _query().
        for (final param in cctkState.parameters.keys) {
          if (param.cmd == cctkType) {
            cctkState.parameters[param]?.mode = mode;
            break;
          }
        }
      }
      _callStateChanged(cctkState);
      return success;
    } catch (_) {
      _apiReady = false;
      if (_shouldShowDepsWarning()) _callDepsChanged(false);
      _callStateChanged(cctkState);
      return false;
    } finally {
      _cctkReleaseMutex();
    }
  }
}
