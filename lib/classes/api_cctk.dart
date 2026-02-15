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
import '../classes/runtime_metrics.dart';
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
  static Future<SharedPreferences>? _prefsFuture;
  static const _uuid = Uuid();

  static final CCTKState cctkState = CCTKState();
  static BiosBackend? _backend;
  static Future<BiosBackend>? _backendCreation;
  static bool _dellBiosProviderAttemptedAndFailed = false;
  /// When true, periodic timer skips starting a new _query() so a waiting request() can run sooner.
  static bool _writePending = false;
  static DateTime? _ensureReadyRetryAfter;
  static int _ensureReadyBackoffSec = 5;

  /// Call from main() to preload SharedPreferences so the first _query() does not wait on getInstance().
  static void initPreload() {
    _prefsFuture ??= SharedPreferences.getInstance();
  }

  /// Call from main() (without awaiting) to pre-warm the backend so the first _query() skips ensureReady().
  static Future<void> ensureBackend() async {
    await BiosProtectionManager.secureReadPassword();
    sourceEnvironment();
    await _getOrCreateBackend();
  }

  /// True when the Missing Dependencies warning should be shown: Linux (CCTK required) or Windows and DellBIOSProvider failed.
  static bool _shouldShowDepsWarning() =>
      Platform.isLinux ||
      (Platform.isWindows && _dellBiosProviderAttemptedAndFailed);

  static Future<BiosBackend> _createBackend() async {
    if (Platform.isLinux) {
      return CctkBackend(_shell);
    }
    if (Platform.isWindows) {
      final dp = DellBiosProviderBackend(_shell);
      if (await dp.ensureReady()) {
        return dp;
      }
      _dellBiosProviderAttemptedAndFailed = true;
      return dp;
    }
    return CctkBackend(_shell);
  }

  /// Selects backend: Linux -> CctkBackend; Windows -> DellBiosProviderBackend only (no CCTK fallback).
  static Future<BiosBackend> _getOrCreateBackend() async {
    if (_backend != null) return _backend!;
    _backendCreation ??= _createBackend();
    final b = await _backendCreation!;
    _backend = b;
    return b;
  }

  ApiCCTK(Duration refreshInternal) {
    sourceEnvironment();
    BiosProtectionManager.secureReadPassword();
    _refreshInternal = refreshInternal;
    _query();
    _timer = Timer.periodic(_refreshInternal, (Timer t) {
      if (_writePending) return;
      _query();
    });
  }
  static void requestUpdate() {
    _timer.cancel();
    _query();
    _timer = Timer.periodic(_refreshInternal, (Timer t) {
      if (_writePending) return;
      _query();
    });
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
    final startedMs = RuntimeMetrics.nowMs();
    if (cctkState.cctkCompatible == false) return false;

    await _cctkAcquire();
    try {
      final backend = await _getOrCreateBackend();
      if (!(_apiReady ?? true)) {
        if (_ensureReadyRetryAfter != null && DateTime.now().isBefore(_ensureReadyRetryAfter!)) {
          RuntimeMetrics.logDuration('apiCctk.query.ensureReadyBackoff', startedMs, extra: 'until=${_ensureReadyRetryAfter!.toIso8601String()}');
          return false;
        }
        _apiReady = await backend
            .ensureReady()
            .timeout(Duration(seconds: Constants.backendEnsureReadyTimeoutSec), onTimeout: () => throw TimeoutException('ensureReady'));
        if (_apiReady!) {
          _ensureReadyRetryAfter = null;
          _ensureReadyBackoffSec = 5;
          _callDepsChanged(true);
        } else if (_shouldShowDepsWarning()) {
          _ensureReadyRetryAfter = DateTime.now().add(Duration(seconds: _ensureReadyBackoffSec));
          _ensureReadyBackoffSec = (_ensureReadyBackoffSec * 2).clamp(5, 60).toInt();
          _callDepsChanged(false);
        }
        if (!(_apiReady ?? false)) return false;
      }

      _prefs ??= await (_prefsFuture ?? SharedPreferences.getInstance());
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
      RuntimeMetrics.logDuration('apiCctk.query', startedMs, extra: 'success=$success');
      return success;
    } catch (_) {
      // Transient failure (e.g. timeout, IO): mark not ready so next _query() re-runs ensureReady().
      _apiReady = false;
      _ensureReadyRetryAfter = DateTime.now().add(Duration(seconds: _ensureReadyBackoffSec));
      _ensureReadyBackoffSec = (_ensureReadyBackoffSec * 2).clamp(5, 60).toInt();
      if (_shouldShowDepsWarning()) _callDepsChanged(false);
      _callStateChanged(cctkState);
      RuntimeMetrics.logDuration('apiCctk.query.exception', startedMs);
      return false;
    } finally {
      _cctkReleaseMutex();
    }
  }

  static Future<bool> request(String cctkType, String mode, {String? requestCode}) async {
    final startedMs = RuntimeMetrics.nowMs();
    _writePending = true;
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
      RuntimeMetrics.logDuration('apiCctk.request', startedMs, extra: 'type=$cctkType success=$success');
      return success;
    } catch (_) {
      _apiReady = false;
      _ensureReadyRetryAfter = DateTime.now().add(Duration(seconds: _ensureReadyBackoffSec));
      _ensureReadyBackoffSec = (_ensureReadyBackoffSec * 2).clamp(5, 60).toInt();
      if (_shouldShowDepsWarning()) _callDepsChanged(false);
      _callStateChanged(cctkState);
      RuntimeMetrics.logDuration('apiCctk.request.exception', startedMs, extra: 'type=$cctkType');
      return false;
    } finally {
      _cctkReleaseMutex();
      _writePending = false;
      _query();
    }
  }
}
