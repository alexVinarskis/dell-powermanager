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
      if (Platform.isLinux) {
        ProcessResult pr = (await shell.run('${Constants.githubApiRequest} ${Constants.githubApiReleases}'))[0];
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
          if (asset.containsKey(Constants.githubApiFieldBrowserDownloadUrl) && asset[Constants.githubApiFieldBrowserDownloadUrl].toString().endsWith('.deb')) {
            result.add(asset[Constants.githubApiFieldBrowserDownloadUrl]);
            break;
          }
        }
        return result;
      } else {
        // ToDo Windows integration;
        return result;
      }
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
      if (Platform.isLinux) {
        List<ProcessResult> prs = (await shell.run('''    
          rm -rf ${Constants.packagesLinuxDownloadPath}/*     
          mkdir -p ${Constants.packagesLinuxDownloadPath}
          curl -L -A "User-Agent Mozilla" $downloadUrl -o ${Constants.packagesLinuxDownloadPath}/$tagname.deb
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

  static Future<bool> installOta(String tagname) async {
    bool result = true;
    try {
      if (Platform.isLinux) {
        ProcessResult pr = (await shell.run('pkexec bash -c "ss=0; apt install -y --allow-downgrades -f ${Constants.packagesLinuxDownloadPath}/$tagname.deb || ((ss++)); rm -rf ${Constants.packagesLinuxDownloadPath}/*  || ((ss++)); exit \$ss"'))[0];
        result = pr.exitCode == 0;
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
