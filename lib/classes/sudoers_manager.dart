import 'dart:io';

import 'package:process_run/shell.dart';

import '../configs/constants.dart';
import '../configs/environment.dart';

class SudoersManager {
  static final _shell = Shell(verbose: Environment.runningDebug, throwOnError: false);
  static const sudoersPatchCmd = 'export PATH="${Constants.apiPathLinux}:\$PATH" && echo "ALL ALL=(ALL) NOPASSWD: \$(which cctk)" | sudo tee /etc/sudoers.d/${Constants.applicationPackageName}';
  static bool? runningSudo;

  static Future<bool> verifySudo() async {
    ProcessResult pr;
    if (Platform.isLinux) {
      // (Linux) Verify that cctk bin was added to sudoers
      pr = (await _shell.run('''bash -c "export PATH="${Constants.apiPathLinux}:\$PATH" && sudo -n \$(which cctk) 2>/dev/null"'''))[0];
      runningSudo = pr.exitCode != 1;
    } else {
      // (Windows) Verify that app is running as admin
      pr = (await _shell.run('''cmd /c cmd /c "${Constants.apiPathWindows}"'''))[0];
      runningSudo = !((pr.stderr.toString() + pr.stdout.toString()).contains("admin/root"));
    }
    return runningSudo!;
  }

  static Future<bool> patchSudoers() async {
    ProcessResult pr = (await _shell.run('''pkexec bash -c '$sudoersPatchCmd' '''))[0];
    return pr.exitCode == 0;
  }
}
