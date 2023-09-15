import 'dart:io';

import 'package:process_run/shell.dart';

import '../configs/constants.dart';

class DependenciesManager {
  static final shell = Shell();

  static Future<bool> verifyDependencies() async {
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
}
