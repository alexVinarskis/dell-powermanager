import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';

import '../classes/cctk_state.dart';
import '../configs/constants.dart';

class Api {
  static final List<Function(bool apiReady)> _callbacksDepsChanged = [];
  static void addCallbacksDepsChanged(var callback)  { _callbacksDepsChanged.add(callback); }
  static void removeCallbacksDepsChanged(var callback) { _callbacksDepsChanged.remove(callback); }

  static final List<Function(CCTKState cctkState)> _callbacksStateChanged = [];
  static void addCallbacksStateChanged(var callback)  { _callbacksStateChanged.add(callback); }
  static void removeCallbacksStateChanged(var callback) { _callbacksStateChanged.remove(callback); }

  static late Duration _refreshInternal;
  static late Timer _timer;
  static bool? apiReady;
  static final shell = Shell(); 
  static CCTKState cctkState = CCTKState();

  Api(Duration refreshInternal) {
    _refreshInternal = refreshInternal;
    _queryApi();
    _timer = Timer.periodic(_refreshInternal, (Timer t) => _queryApi());
  }
  static void requestUpdate() {
    _timer.cancel();
    _queryApi();
    _timer = Timer.periodic(_refreshInternal, (Timer t) => _queryApi());
  }
  static void stop() {
    _timer.cancel();
  }

  static Future<bool> downloadDependencies() async {
    bool result = true;
    try {
      if (Platform.isLinux) {
        // handle download links individually, since one is tarred and need special handling in installation anyway
        List<ProcessResult> prs = (await shell.run('''    
          rm -rf ${Constants.packagesLinuxDownloadPath}/*     
          mkdir -p ${Constants.packagesLinuxDownloadPath}
          wget --user-agent="Mozilla" ${Constants.packagesLinuxUrlLibssl[0]} -O ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlLibssl[1]}
          wget --user-agent="Mozilla" ${Constants.packagesLinuxUrlDell[0]}   -O ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlDell[1]}
          '''));
        for (ProcessResult pr in prs) {
          result = pr.exitCode == 0 && result;
        }
        return result;
      } else {
        // ToDo Windows integration;
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  static Future<bool> installDependencies() async {
    bool result = true;
    try {
      if (Platform.isLinux) {
        // Install libssl *first*, else after dell command cli is install, it may be queried, and may crash if libssl is missing
        List<ProcessResult> prs = (await shell.run('''
          tar -xf ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlDell[1]} -C ${Constants.packagesLinuxDownloadPath}
          pkexec sh -c "apt install -y -f ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlLibssl[1]}; apt install -y -f ${Constants.packagesLinuxDownloadPath}/*.deb; rm -rf ${Constants.packagesLinuxDownloadPath}/*"
          '''));
        for (ProcessResult pr in prs) {
          result = pr.exitCode == 0 && result;
        }
        return result;
      } else {
        // ToDo Windows integration;
        return false;
      }
    } catch (e) {
      return false;
    }
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

  static Future<bool> _queryApi() async {
    if (!(apiReady ?? false)) {
      apiReady = await _verifyDependencies();
      _callDepsChanged(apiReady!);
      if (!(apiReady ?? false)) return false;
    }
    // create cctk query arg
    String arg = '';
    for (var param in CCTKState.queryParameters) {
      arg+= " --${param.cmd}";
    }
    late ProcessResult pr;
    // get response
    try {
      if (Platform.isLinux) {
        pr = (await shell.run('sudo ${Constants.apiPathLinux} $arg'))[0];
      } else {
        // ToDo Windows integration;
        return false;
      }
    } catch (e) {
      return false;
    }
    // process response
    if (!_processApiReponse(pr)) {
      return false;
    }
    // notify listeners
    _callStateChanged(cctkState);
    return true;
  }
  static Future<bool> _verifyDependencies() async {
    bool result = true;
    try {
      if (Platform.isLinux) {
        for (String package in Constants.packagesLinux) {
          ProcessResult pr = (await shell.run('dpkg -s $package'))[0];
          result = pr.exitCode == 0 &&  pr.stdout.toString().contains("installed") && result;
        }
        return result;
      } else {
        // ToDo Windows integration;
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  static bool _processApiReponse(ProcessResult pr) {
     if (pr.exitCode != 0) {
      return false;
    }
    for (String output in pr.stdout.toString().split("\n")) {
      List<String> argAndValue = output.split("=");
      if (argAndValue.length < 2) continue;
      for (var paramKey in cctkState.parameters.keys) {
        if (paramKey.cmd == argAndValue[0]) {
          cctkState.parameters[paramKey] = argAndValue[1]; 
        }
      }
    }
    return true;
  }

  static Future<bool> requestAction(String cctkType, String mode) async {
    late ProcessResult pr;
    try {
      if (Platform.isLinux) {
        pr = (await shell.run('sudo ${Constants.apiPathLinux} --$cctkType=$mode'))[0];
      } else {
        // ToDo Windows integration;
        return false;
      }
    } catch (e) {
      return false;
    }
    return _processApiReponse(pr);
  }
}
