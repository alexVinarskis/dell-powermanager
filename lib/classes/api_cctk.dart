import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';

import '../configs/constants.dart';
import '../classes/dependencies_manager.dart';
import '../classes/cctk_state.dart';
import '../classes/cctk.dart';

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
  static final _shell = Shell(throwOnError: false);

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
    for (var callback in _callbacksDepsChanged) {
      callback(apiReady);
    }
  }
  static void _callStateChanged(CCTKState cctkState) {
    for (var callback in _callbacksStateChanged) {
      callback(cctkState);
    }
  }

  static Future<bool> _query() async {
    if (!(_apiReady ?? false)) {
      _apiReady = await DependenciesManager.verifyDependencies();
      _callDepsChanged(_apiReady!);
      if (!(_apiReady ?? false)) return false;
    }
    // create cctk query arg
    String arg = '';
    for (var param in _queryParameters) {
      arg+= " --${param.cmd}";
    }
    late ProcessResult pr;
    // get response
    if (Platform.isLinux) {
      pr = (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && sudo \$(which cctk) $arg"'''))[0];
    } else {
      // Running 'CMD /c' in PS breaks '"', yet works in CMD. Hack to wrap it in `cmd /c` twise. Thanks Microsoft.
      pr = (await _shell.run('''cmd /c cmd /c "${Constants.apiPathWindows}" $arg'''))[0];
    }
    // process response
    if (!_processResponse(pr)) {
      return false;
    }
    // notify listeners
    _callStateChanged(cctkState);
    return true;
  }
  static bool _processResponse(ProcessResult pr) {
    if (pr.exitCode != 0) {
      return false;
    }
    for (String output in pr.stdout.toString().split("\n")) {
      List<String> argAndValue = output.trim().replaceAll("\r", "").split("=");
      if (argAndValue.length < 2) continue;
      for (var paramKey in cctkState.parameters.keys) {
        if (argAndValue[0].contains(paramKey.cmd)) {
          cctkState.parameters[paramKey] = argAndValue[1];
        }
      }
    }
    return true;
  }

  static Future<bool> request(String cctkType, String mode) async {
    late ProcessResult pr;
    if (Platform.isLinux) {
      pr = (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && sudo \$(which cctk) --$cctkType=$mode"'''))[0];
    } else {
      pr = (await _shell.run('''cmd /c cmd /c "${Constants.apiPathWindows}" --$cctkType=$mode'''))[0];
    }
    // process response
    if (!_processResponse(pr)) {
      return false;
    }
    // notify listeners
    _callStateChanged(cctkState);
    return true;
  }
}
