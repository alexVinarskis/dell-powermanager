import 'dart:io';

import 'package:process_run/shell.dart';

import '../configs/constants.dart';
import '../configs/environment.dart';

class DependenciesManager {
  static final _shell = Shell(verbose: Environment.runningDebug, throwOnError: false);
  static bool? supportsAutoinstall;

  static Future<void> verifySupportsAutoinstall() async {
    if (Platform.isLinux) {
      // For linux, only .deb via `apt` is supported for autoinstall
      ProcessResult pr = (await _shell.run('''which apt'''))[0];
      supportsAutoinstall = pr.exitCode == 0;
    } else {
      // Windows supports autoinstall by default via .msi
      supportsAutoinstall = true;
    }
  }

  static Future<bool> verifyDependencies() async {
    if (Platform.isWindows) {
      // On Windows the app uses DellBIOSProvider only; CCTK is not checked.
      return false;
    }
    ProcessResult pr = (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && which cctk && [[ \$( \$(which cctk) 2>&1) != *libcrypto* ]]"'''))[0];
    if (pr.exitCode == 0) {
      return true;
    }
    if (supportsAutoinstall == null) {
      await verifySupportsAutoinstall();
    }
    return false;
  }

  static Future<bool> downloadDependencies() async {
    if (Platform.isWindows) {
      // On Windows the app uses DellBIOSProvider only; CCTK is not installed via this flow.
      return false;
    }
    bool result = true;
    List<ProcessResult> prs;
    // handle download links individually, since one is tarred and need special handling in installation anyway
    prs = (await _shell.run('''
      rm -rf ${Constants.packagesLinuxDownloadPath}/*     
      mkdir -p ${Constants.packagesLinuxDownloadPath}
      curl -f -L -A "User-Agent Mozilla" ${Constants.packagesLinuxUrlDell[0]}   -o ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlDell[1]}
      '''));
    for (ProcessResult pr in prs) {
      result = pr.exitCode == 0 && result;
    }
    return result;
  }

  static Future<bool> installDependencies() async {
    if (Platform.isWindows) {
      // On Windows the app uses DellBIOSProvider only; CCTK is not installed via this flow.
      return false;
    }
    bool result = true;
    List<ProcessResult> prs;
    prs = (await _shell.run('''
      tar -xf ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlDell[1]} -C ${Constants.packagesLinuxDownloadPath}
      pkexec bash -c "ss=0; apt install -y -f ${Constants.packagesLinuxDownloadPath}/*.deb || ((ss++)); rm -rf ${Constants.packagesLinuxDownloadPath}/* || ((ss++)); exit \$ss"
      '''));
    for (ProcessResult pr in prs) {
      result = pr.exitCode == 0 && result;
    }
    return result;
  }
}
