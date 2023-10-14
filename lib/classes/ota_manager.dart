import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:version/version.dart';

import '../configs/constants.dart';

class OtaManager {
  static final shell = Shell();

  // [tagname, releaseUrl, downloadUrl]
  static Future<List<String>> checkLatestOta() async {
    List<String> result = [];
    try {
      ProcessResult pr = (await shell.run('${Platform.isLinux ? "" : "cmd /c"} ${Constants.githubApiRequest} ${Constants.githubApiReleases}'))[0];
      if (pr.exitCode != 0) {
        return result;
      }
      Map<dynamic, dynamic> json = jsonDecode(pr.stdout.toString());

      // fetch tagname & url
      if (!json.containsKey(Constants.githubApiFieldTagname)) {
        return result;
      }
      result.add(json[Constants.githubApiFieldTagname]);
      if (!json.containsKey(Constants.githubApiFieldHtmlUrl)) {
        return result;
      }
      result.add(json[Constants.githubApiFieldHtmlUrl]);

      // fetch download url
      if (!json.containsKey(Constants.githubApiFieldAssets)) {
        return result;
      }
      for (Map<dynamic, dynamic> asset in json[Constants.githubApiFieldAssets]) {
        if (asset.containsKey(Constants.githubApiFieldBrowserDownloadUrl) && asset[Constants.githubApiFieldBrowserDownloadUrl].toString().endsWith(Platform.isLinux ? '.deb' : '.msi')) {
          result.add(asset[Constants.githubApiFieldBrowserDownloadUrl]);
          break;
        }
      }
      return result;
    } catch (e) {
      return result;
    }
  }

  static bool compareUpdateRequired(String tagname) {
    Version currentVersion = Version.parse(Constants.applicationVersion.split('-')[0]);
    Version latestVersion = Version.parse(tagname);  
    return latestVersion > currentVersion;
  }

  static Future<bool> downloadOta(String tagname, String downloadUrl) async {
    bool result = true;
    try {
      List<ProcessResult> prs;
      if (Platform.isLinux) {
        prs = (await shell.run('''    
          rm -rf ${Constants.packagesLinuxDownloadPath}/*     
          mkdir -p ${Constants.packagesLinuxDownloadPath}
          curl -L -A "User-Agent Mozilla" $downloadUrl -o ${Constants.packagesLinuxDownloadPath}/$tagname.deb
          '''));
      } else {
        prs = (await shell.run('''
          cmd /c IF EXIST "${Constants.packagesWindowsDownloadPath}" rmdir /s /q "${Constants.packagesWindowsDownloadPath}"
          cmd /c mkdir "${Constants.packagesWindowsDownloadPath}"
          cmd /c curl -L -A "User-Agent Edge" $downloadUrl -o "${Constants.packagesWindowsDownloadPath}\\$tagname.msi"
          '''));
      }
      for (ProcessResult pr in prs) {
        result = pr.exitCode == 0 && result;
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> installOta(String tagname) async {
    try {
      ProcessResult pr;
      if (Platform.isLinux) {
        pr = (await shell.run('pkexec bash -c "ss=0; apt install -y --allow-downgrades -f ${Constants.packagesLinuxDownloadPath}/$tagname.deb || ((ss++)); rm -rf ${Constants.packagesLinuxDownloadPath}/*  || ((ss++)); exit \$ss"'))[0];
      } else {
        pr = (await shell.run('cmd /c ${Constants.packagesWindowsDownloadPath}/$tagname.msi && cmd /c IF EXIST "${Constants.packagesWindowsDownloadPath}" rmdir /s /q "${Constants.packagesWindowsDownloadPath}"'))[0];
      }
      return pr.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
