import 'dart:io';

import 'package:process_run/shell.dart';

import '../configs/constants.dart';

class DependenciesManager {
  static final _shell = Shell(throwOnError: false);
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
    ProcessResult pr;
    if (Platform.isLinux) {
      pr = (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && which cctk && [[ \$( \$(which cctk) 2>&1) != *libcrypto* ]]"'''))[0];
    } else {
      pr = (await _shell.run('''cmd /c dir "${Constants.apiPathWindows}"'''))[0];
    }
    if (pr.exitCode == 0) {
      return true;
    }
    if (supportsAutoinstall == null) {
      await verifySupportsAutoinstall();
    }
    return false;
  }

  static Future<bool> downloadDependencies() async {
    bool result = true;
    List<ProcessResult> prs;
    if (Platform.isLinux) {
      // handle download links individually, since one is tarred and need special handling in installation anyway
      prs = (await _shell.run('''
        rm -rf ${Constants.packagesLinuxDownloadPath}/*     
        mkdir -p ${Constants.packagesLinuxDownloadPath}
        curl -f -L -A "User-Agent Mozilla" ${Constants.packagesLinuxUrlLibssl[0]} -o ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlLibssl[1]}
        curl -f -L -A "User-Agent Mozilla" ${Constants.packagesLinuxUrlDell[0]}   -o ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlDell[1]}
        '''));
    } else {
      prs = (await _shell.run('''
        cmd /c IF EXIST "${Constants.packagesWindowsDownloadPath}" rmdir /s /q "${Constants.packagesWindowsDownloadPath}"
        cmd /c mkdir "${Constants.packagesWindowsDownloadPath}"
        cmd /c curl -f -L -A "User-Agent Edge" ${Constants.packagesWindowsUrlDell[0]} -o "${Constants.packagesWindowsDownloadPath}\\${Constants.packagesWindowsUrlDell[1]}"
        '''));
    }
    for (ProcessResult pr in prs) {
      result = pr.exitCode == 0 && result;
    }
    return result;
  }

  static Future<bool> installDependencies() async {
    bool result = true;
    List<ProcessResult> prs;
    if (Platform.isLinux) {
      // Install libssl *first*, else after dell command cli is install, it may be queried, and may crash if libssl is missing
      prs = (await _shell.run('''
        tar -xf ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlDell[1]} -C ${Constants.packagesLinuxDownloadPath}
        pkexec bash -c "ss=0; apt install -y -f ${Constants.packagesLinuxDownloadPath}/${Constants.packagesLinuxUrlLibssl[1]} || ((ss++)); apt install -y -f ${Constants.packagesLinuxDownloadPath}/*.deb || ((ss++)); rm -rf ${Constants.packagesLinuxDownloadPath}/* || ((ss++)); exit \$ss"
        '''));
    } else {
      prs = (await _shell.run('''
        cmd /c ${Constants.packagesWindowsDownloadPath}\\${Constants.packagesWindowsUrlDell[1]} /s
        cmd /c IF EXIST "${Constants.packagesWindowsDownloadPath}" rmdir /s /q "${Constants.packagesWindowsDownloadPath}"
        '''));
    }
    for (ProcessResult pr in prs) {
      result = pr.exitCode == 0 && result;
    }
    return result;
  }
}
