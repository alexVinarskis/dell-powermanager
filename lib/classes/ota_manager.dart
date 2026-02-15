import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';

import '../classes/dependencies_manager.dart';
import '../configs/constants.dart';
import '../configs/environment.dart';
import 'runtime_metrics.dart';

class OtaManager {
  static final _shell = Shell(verbose: Environment.runningDebug, throwOnError: false);
  static SharedPreferences? _prefs;
  static const _prefNameOtaCheckEnabled = "otaCheckEnabled";
  static const _prefNameOtaLatestResult = "otaLatestResult";
  static const _prefNameOtaLastCheckMs = "otaLastCheckMs";
  static const _otaCheckTtlMs = 24 * 60 * 60 * 1000;

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
      checkLatestOta(otaCheckEnabled: value, useCache: false).then((latestOta) => _callOtaChanged(latestOta));
    }
  }
  static Future<bool> isOtaCheckEnabled() async {
    _prefs ??= await SharedPreferences.getInstance();
    bool? isOtaCheckEnabled = _prefs?.getBool(_prefNameOtaCheckEnabled);
    if (isOtaCheckEnabled == null) {
      isOtaCheckEnabled = true;
      await _prefs?.setBool(_prefNameOtaCheckEnabled, isOtaCheckEnabled);
      checkLatestOta(otaCheckEnabled: isOtaCheckEnabled, useCache: false).then((latestOta) => _callOtaChanged(latestOta));
    }
    return isOtaCheckEnabled;
  }

  static Future<List<String>> getCachedLatestOta() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonString = _prefs?.getString(_prefNameOtaLatestResult);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(jsonString);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return [];
  }

  // [tagname, releaseUrl, downloadUrl]
  static Future<List<String>> checkLatestOta({bool? otaCheckEnabled, bool useCache = true}) async {
    final startedMs = RuntimeMetrics.nowMs();
    _prefs ??= await SharedPreferences.getInstance();
    otaCheckEnabled ??= await isOtaCheckEnabled();
    if (!otaCheckEnabled) {
      RuntimeMetrics.logDuration('ota.checkLatestOta.skipDisabled', startedMs);
      return [];
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastCheckMs = _prefs?.getInt(_prefNameOtaLastCheckMs) ?? 0;
    if (useCache && nowMs - lastCheckMs < _otaCheckTtlMs) {
      final cached = await getCachedLatestOta();
      if (cached.isNotEmpty) {
        RuntimeMetrics.logDuration('ota.checkLatestOta.cacheHit', startedMs);
        return cached;
      }
    }

    List<String> result = [];
    RuntimeMetrics.increment('process.otaApi');
    ProcessResult pr = (await _shell.run('${Platform.isLinux ? "" : "cmd /c"} ${Constants.githubApiRequest} ${Constants.githubApiReleases}'))[0];
    if (pr.exitCode != 0) {
      RuntimeMetrics.logDuration('ota.checkLatestOta.apiFailed', startedMs, extra: 'exit=${pr.exitCode}');
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
    if (DependenciesManager.supportsAutoinstall == null) {
      await DependenciesManager.verifySupportsAutoinstall();
    }
    String? arch;
    if (Platform.isLinux && DependenciesManager.supportsAutoinstall == true) {
      RuntimeMetrics.increment('process.otaDpkgArch');
      arch = (await _shell.run('dpkg --print-architecture'))[0].stdout.toString().trim();
    }
    for (Map<dynamic, dynamic> asset in json[Constants.githubApiFieldAssets]) {
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
        if (arch == null || arch.isEmpty) {
          continue;
        }
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
    await _prefs?.setInt(_prefNameOtaLastCheckMs, nowMs);
    await _prefs?.setString(_prefNameOtaLatestResult, jsonEncode(result));
    RuntimeMetrics.logDuration('ota.checkLatestOta.network', startedMs);
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
