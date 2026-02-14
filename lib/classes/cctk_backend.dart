import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../configs/constants.dart';
import '../configs/environment.dart';
import 'bios_backend.dart';
import 'cctk.dart';
import 'cctk_state.dart';

/// BIOS backend using Dell Command | Configure (cctk) CLI.
class CctkBackend implements BiosBackend {
  CctkBackend(this._shell);

  final Shell _shell;

  @override
  void sourceEnvironment(Shell shell) {
    // Shell is passed from ApiCCTK; env is set there via ApiCCTK.sourceEnvironment
  }

  @override
  Future<bool> ensureReady() async {
    if (Platform.isLinux) {
      final pr = (await _shell.run(
          '''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && which cctk && [[ \$( \$(which cctk) 2>&1) != *libcrypto* ]]"'''))[0];
      return pr.exitCode == 0;
    } else {
      final pr = (await _shell.run('''cmd /c dir "${Constants.apiPathWindows}"'''))[0];
      return pr.exitCode == 0;
    }
  }

  @override
  Future<bool> query(List<dynamic> queryParams, CCTKState cctkState, SharedPreferences? prefs) async {
    String arg = '';
    for (var param in queryParams) {
      if (cctkState.parameters[param]?.supported == null) {
        String? cachedString = prefs?.getString("cctkSupportedMode${param.cmd}");
        if (cachedString != null && cachedString.isNotEmpty && jsonDecode(cachedString) != null) {
          final cachedMap = jsonDecode(cachedString) as Map<String, dynamic>;
          cctkState.parameters[param]?.supported = cachedMap.cast<String, bool>();
        } else {
          if (!_processSupported(await _runCctk("-H --${param.cmd}"), param, cctkState)) {
            if (cctkState.cctkCompatible != false) return true;
            return false;
          }
          prefs?.setString("cctkSupportedMode${param.cmd}", jsonEncode(cctkState.parameters[param]?.supported));
        }
      }
      if (cctkState.parameters[param]?.supported?.containsValue(true) ?? false) {
        arg += " --${param.cmd}";
      }
    }
    if (arg.isEmpty) return false;
    return _processResponse(await _runCctk(arg), cctkState);
  }

  @override
  Future<bool> request(String cctkType, String mode, CCTKState cctkState, {String? requestCode}) async {
    late String cmd;
    if (Platform.isLinux) {
      cmd = '--$cctkType=$mode${Environment.biosPwd == null ? "" : " --ValSetupPwd=\$${Constants.varnameBiosPwd} --ValSysPwd=\$${Constants.varnameBiosPwd}"}';
    } else {
      cmd = '--$cctkType=$mode${Environment.biosPwd == null ? "" : " --ValSetupPwd=%${Constants.varnameBiosPwd}% --ValSysPwd=%${Constants.varnameBiosPwd}%"}';
    }
    final pr = await _runCctk(cmd);
    final success = _processResponse(pr, cctkState);
    cctkState.exitStateWrite = ExitState(pr.exitCode, cctkType, mode, requestCode ?? const Uuid().v4());
    return success;
  }

  Future<ProcessResult> _runCctk(String arg) async {
    if (Platform.isLinux) {
      return (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && sudo -n \$(which cctk) $arg"'''))[0];
    } else {
      return (await _shell.run('''cmd /c cmd /c "${Constants.apiPathWindows}" $arg'''))[0];
    }
  }

  bool _processResponse(ProcessResult pr, CCTKState cctkState) {
    cctkState.exitCodeRead = pr.exitCode;
    if (pr.exitCode != 0) return false;
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

  bool _processSupported(ProcessResult pr, dynamic param, CCTKState cctkState) {
    cctkState.exitCodeRead = pr.exitCode;
    String output = (pr.stderr.toString() + pr.stdout.toString()).replaceAll("\n", "");
    if ((output.isEmpty && pr.exitCode == 0) || output.contains("WMI-ACPI")) {
      cctkState.cctkCompatible = false;
      return false;
    }
    if (pr.exitCode != 0) return false;
    Map<String, bool> supportedModes = {};
    for (String line in pr.stdout.toString().replaceAll("\r", "").split("\n")) {
      if (!line.contains("Arguments:")) continue;
      List<String> arguments = line.replaceAll("Arguments:", "").replaceAll(" ", "").split("|");
      for (String argument in arguments) {
        supportedModes.addEntries({argument.replaceAll("+", ""): argument.contains("+")}.entries);
      }
    }
    cctkState.parameters[param]?.supported = supportedModes;
    return true;
  }
}
