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
  static bool _cctkMutexLocked = false;
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

  static void _cctkLock() { _cctkMutexLocked = true; }
  static void _cctkRelease() { _cctkMutexLocked = false; }
  static bool _isCctkLocked() => _cctkMutexLocked;

  static Future<bool> _query() async {
    if (_isCctkLocked() || cctkState.cctkCompatible == false) return false;

    final backend = await _getOrCreateBackend();
    if (!(_apiReady ?? true)) {
      _apiReady = await backend.ensureReady();
      if (_apiReady!) {
        _callDepsChanged(true);
      } else if (_shouldShowDepsWarning()) {
        _callDepsChanged(false);
      }
      if (!(_apiReady ?? false)) return false;
    }

    _cctkLock();
    _prefs ??= await SharedPreferences.getInstance();
    final success = await backend.query(List.from(_queryParameters), cctkState, _prefs);
    _cctkRelease();
    if (!success) {
      _apiReady = false;
      if (_shouldShowDepsWarning()) _callDepsChanged(false);
    } else {
      _apiReady = true;
      _callDepsChanged(true);
    }
    _callStateChanged(cctkState);
    return success;
  }

  static Future<bool> request(String cctkType, String mode, {String? requestCode}) async {
    final backend = await _getOrCreateBackend();
    final success = await backend.request(cctkType, mode, cctkState, requestCode: requestCode ?? _uuid.v4());
    if (!success) {
      _apiReady = false;
      if (_shouldShowDepsWarning()) _callDepsChanged(false);
    } else {
      _callDepsChanged(true);
    }
    _callStateChanged(cctkState);
    return success;
  }
}
