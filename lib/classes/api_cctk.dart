import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configs/constants.dart';
import '../classes/dependencies_manager.dart';
import '../classes/cctk_state.dart';
import '../classes/cctk.dart';
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
  static final _shell = Shell(verbose: Environment.runningDebug, throwOnError: false);

  static SharedPreferences? _prefs;

  static final CCTKState cctkState = CCTKState();

  ApiCCTK(Duration refreshInternal) {
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

  static void _callDepsChanged(bool apiReady) {
    var dubList = List.from(_callbacksDepsChanged);
    for (var callback in dubList) {
      callback(apiReady);
    }
  }
  static void _callStateChanged(CCTKState cctkState) {
    var dubList = List.from(_callbacksStateChanged);
    for (var callback in dubList) {
      callback(cctkState);
    }
  }

  static void _cctkLock() {
    _cctkMutexLocked = true;
  }
  static void _cctkRelease() {
    _cctkMutexLocked = false;
  }
  static bool _isCctkLocked() {
    return _cctkMutexLocked;
  }

  static Future<bool> _query() async {
    // prevent concurrent queries, these seem to really slow down everything
    if (_isCctkLocked() || cctkState.cctkCompatible == false) {
      return false;
    }
    if (!(_apiReady ?? true)) {
      _apiReady = await DependenciesManager.verifyDependencies();
      _callDepsChanged(_apiReady!);
      if (!(_apiReady ?? false)) return false;
    }
    _cctkLock();
    // create cctk query arg
    String arg = '';
    var dubList = List.from(_queryParameters);
    for (var param in dubList) {
      // verify that parameter is supported *before* querying it
      if (cctkState.parameters[param]?.supported == null) {
        /* attempt to read cached data first */
        _prefs ??= await SharedPreferences.getInstance();
        String cachedString = _prefs?.getString("cctkSupportedMode${param.cmd}") ?? "";
        if (cachedString.isNotEmpty && jsonDecode(cachedString) != null) {
          Map<String, dynamic>? cachedMap = jsonDecode(cachedString) as Map<String, dynamic>;
          cctkState.parameters[param]?.supported = cachedMap.cast<String, bool>();
        } else {
          /* fetch supported modes from cctk (slow) */
          if (!_processSupported(await _runCctk("-H --${param.cmd}"), param) && !(cctkState.cctkCompatible?? true)) {
            _cctkRelease();
            _callStateChanged(cctkState);
            return false;
          }
          /* update cached data */
          await _prefs?.setString("cctkSupportedMode${param.cmd}", jsonEncode(cctkState.parameters[param]?.supported));
        }
      }
      if (cctkState.parameters[param]?.supported?.containsValue(true) ?? false) {
        arg+= " --${param.cmd}";
      }
    }
    if (arg.isEmpty) {
      _cctkRelease();
      _callStateChanged(cctkState);
      return false;
    }
    // get & process response
    bool success = _processResponse(await _runCctk(arg));
    _cctkRelease();
    _callStateChanged(cctkState);
    return success;
  }

  static bool _processResponse(ProcessResult pr) {
    cctkState.exitCodeRead = pr.exitCode;
    if (pr.exitCode != 0) {
      _apiReady ??= false;
      return false;
    } else {
      _apiReady ??= true;
    }
    for (String output in pr.stdout.toString().split("\n")) {
      List<String> argAndValue = output.trim().replaceAll("\r", "").split("=");
      if (argAndValue.length < 2) continue;
      for (var paramKey in cctkState.parameters.keys) {
        if (argAndValue[0].contains(paramKey.cmd)) {
          cctkState.parameters[paramKey]?.mode = argAndValue[1];
        }
      }
    }
    return true;
  }

  static bool _processSupported(ProcessResult pr, var param) {
    cctkState.exitCodeRead = pr.exitCode;
    String output = (pr.stderr.toString() + pr.stdout.toString()).replaceAll("\n", "");
    if ((output.isEmpty && pr.exitCode == 0) || output.contains("WMI-ACPI")) {
      cctkState.cctkCompatible = false;
      return false;
    }
    if (pr.exitCode != 0) {
      _apiReady ??= false;
      return false;
    } else {
      _apiReady ??= true;
    }
    Map<String, bool> supportedModes = {};
    for (String output in pr.stdout.toString().replaceAll("\r", "").split("\n")) {
      if (!output.contains("Arguments:")) {
        continue;
      }
      List<String> arguments = output.replaceAll("Arguments:", "").replaceAll(" ", "").split("|");
      for (String argument in arguments) {
        supportedModes.addEntries({argument.replaceAll("+", ""): argument.contains("+")}.entries);
      }
    }
    cctkState.parameters[param]?.supported = supportedModes;
    return true;
  }

  static Future<bool> request(String cctkType, String mode) async {
    /* Query, process, and respond */
    ProcessResult pr = await _runCctk('--$cctkType=$mode');
    bool success = _processResponse(pr);
    cctkState.exitStateWrite = ExitState(pr.exitCode, cctkType, mode);
    _callStateChanged(cctkState);
    return success;
  }

  static Future<ProcessResult> _runCctk(String arg) async {
    if (Platform.isLinux) {
      return (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && sudo -n \$(which cctk) $arg"'''))[0];
    } else {
      return (await _shell.run('''cmd /c cmd /c "${Constants.apiPathWindows}" $arg'''))[0];
    }
  }
}
