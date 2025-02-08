import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';

import '../classes/dependencies_manager.dart';
import '../configs/constants.dart';
import '../configs/environment.dart';

class OtaManager {
  static final _shell = Shell(verbose: Environment.runningDebug, throwOnError: false);
  static SharedPreferences? _prefs;
  static const _prefNameOtaCheckEnabled = "otaCheckEnabled";

  static final List<Function(List<String> latestOta)> _callbacksOtaChanged = [];
  static void addCallbacksOtaChanged(var callback)  { _callbacksOtaChanged.add(callback); }
  static void removeCallbacksOtaChanged(var callback) { _callbacksOtaChanged.remove(callback); }
  static void _callOtaChanged(List<String> latestOta) {
    var dubList = List.from(_callbacksOtaChanged);
    for (var callback in dubList) {
      callback(latestOta);
    }
  }

  static Future<void> setOtaCheckEnabled(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    bool previousValue = await isOtaCheckEnabled();
    if (value != previousValue) {
      await _prefs?.setBool(_prefNameOtaCheckEnabled, value);
      checkLatestOta(otaCheckEnabled: value).then((latestOta) => _callOtaChanged(latestOta));
    }
  }
  static Future<bool> isOtaCheckEnabled() async {
    _prefs ??= await SharedPreferences.getInstance();
    bool? isOtaCheckEnabled = _prefs?.getBool(_prefNameOtaCheckEnabled);
    if (isOtaCheckEnabled == null) {
      isOtaCheckEnabled = true;
      await _prefs?.setBool(_prefNameOtaCheckEnabled, isOtaCheckEnabled);
      checkLatestOta(otaCheckEnabled: isOtaCheckEnabled).then((latestOta) => _callOtaChanged(latestOta));
    }
    return isOtaCheckEnabled;
  }

  // [tagname, releaseUrl, downloadUrl]
  static Future<List<String>> checkLatestOta({bool? otaCheckEnabled}) async {
    otaCheckEnabled ??= await isOtaCheckEnabled();
    if (!otaCheckEnabled) {
      return [];
    }
    List<String> result = [];
    ProcessResult pr = (await _shell.run('${Platform.isLinux ? "" : "cmd /c"} ${Constants.githubApiRequest} ${Constants.githubApiReleases}'))[0];
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
      if (DependenciesManager.supportsAutoinstall == null) {
        await DependenciesManager.verifySupportsAutoinstall();
      }
      // For linux, only .deb is supported for autoinstall
      if (!DependenciesManager.supportsAutoinstall! ||
          !asset.containsKey(Constants.githubApiFieldBrowserDownloadUrl)) {
        continue;
      }
      if (Platform.isWindows) {
        if (asset[Constants.githubApiFieldBrowserDownloadUrl]
            .toString()
            .endsWith('.msi')) {
          result.add(asset[Constants.githubApiFieldBrowserDownloadUrl]);
          break;
        }
      } else {
        String arch = (await _shell.run('dpkg --print-architecture'))[0].stdout.toString();
        if (asset[Constants.githubApiFieldBrowserDownloadUrl]
            .toString()
            .endsWith('.deb') &&
            asset[Constants.githubApiFieldBrowserDownloadUrl]
            .toString().contains(arch) ) {
          result.add(asset[Constants.githubApiFieldBrowserDownloadUrl]);
          break;
        }
      }
    }
    return result;
  }

  static bool compareUpdateRequired(String tagname) {
    Version currentVersion = Version.parse(Constants.applicationVersion.split('-')[0]);
    Version latestVersion = Version.parse(tagname);  
    return latestVersion > currentVersion;
  }

  static Future<bool> downloadOta(String tagname, String downloadUrl) async {
    bool result = true;
    List<ProcessResult> prs;
    if (Platform.isLinux) {
      prs = (await _shell.run('''    
        rm -rf ${Constants.packagesLinuxDownloadPath}/*     
        mkdir -p ${Constants.packagesLinuxDownloadPath}
        curl -f -L -A "User-Agent Mozilla" $downloadUrl -o ${Constants.packagesLinuxDownloadPath}/$tagname.deb
        '''));
    } else {
      prs = (await _shell.run('''
        cmd /c IF EXIST "${Constants.packagesWindowsDownloadPath}" rmdir /s /q "${Constants.packagesWindowsDownloadPath}"
        cmd /c mkdir "${Constants.packagesWindowsDownloadPath}"
        cmd /c curl -f -L -A "User-Agent Edge" $downloadUrl -o "${Constants.packagesWindowsDownloadPath}\\$tagname.msi"
        '''));
    }
    for (ProcessResult pr in prs) {
      result = pr.exitCode == 0 && result;
    }
    return result;
  }

  static Future<bool> installOta(String tagname) async {
    ProcessResult pr;
    if (Platform.isLinux) {
      pr = (await _shell.run('pkexec bash -c "ss=0; apt install -y --allow-downgrades -f ${Constants.packagesLinuxDownloadPath}/$tagname.deb || ((ss++)); rm -rf ${Constants.packagesLinuxDownloadPath}/*  || ((ss++)); exit \$ss"'))[0];
    } else {
      pr = (await _shell.run('cmd /c ${Constants.packagesWindowsDownloadPath}/$tagname.msi && cmd /c IF EXIST "${Constants.packagesWindowsDownloadPath}" rmdir /s /q "${Constants.packagesWindowsDownloadPath}"'))[0];
    }
    return pr.exitCode == 0;
  }
}
