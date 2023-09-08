import 'dart:async';
import 'package:dell_powermanager/configs/constants.dart';
import 'dart:io';

import 'package:process_run/shell.dart';

class Api {
  static final List<Function(bool apiReady)> _callbacksDepsChanged = [];
  static void addCallbacksDepsChanged(var callback)  { _callbacksDepsChanged.add(callback); }
  static void removeCallsbacksDepsChanged(var callback) { _callbacksDepsChanged.remove(callback); }

  static late Timer _timer;
  static bool? apiReady;
  static final shell = Shell(); 

  Api(Duration refreshInternal) {
    _queryApi();
    _timer = Timer.periodic(refreshInternal, (Timer t) => _queryApi());
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
  static void _queryApi() async {
    if (!(apiReady ?? false)) {
      apiReady = await _verifyDependencies();
      _callDepsChanged(apiReady!);
      if (!(apiReady ?? false)) return;
    }
    // ToDo query command-configure
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
  static Future<bool> requestAction(String cctkType, String mode) async {
    try {
      if (Platform.isLinux) {
        ProcessResult pr = (await shell.run('sudo ${Constants.apiPathLinux} --$cctkType=$mode'))[0];
        return pr.exitCode == 0;
      } else {
        // ToDo Windows integration;
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
