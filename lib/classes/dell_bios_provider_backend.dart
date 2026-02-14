import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../configs/constants.dart';
import '../configs/environment.dart';
import 'cctk.dart';
import 'cctk_state.dart';

/// BIOS backend using DellBIOSProvider PowerShell module (Windows only).
class DellBiosProviderBackend implements BiosBackend {
  DellBiosProviderBackend(this._shell);

  final Shell _shell;
  static const _moduleName = 'DellBIOSProvider';

  @override
  void sourceEnvironment(Shell shell) {
    // BIOS_PWD is passed via ApiCCTK's shell environment for -Password $env:BIOS_PWD
  }

  Future<ProcessResult> _runPwsh(String script, {bool includeTls = false}) async {
    final preamble = includeTls
        ? r'[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; '
        : '';
    final fullScript = preamble + script;
    final env = <String, String>{...Platform.environment};
    if (Environment.biosPwd != null) env[Constants.varnameBiosPwd] = Environment.biosPwd!;
    final result = await Process.run(
      'pwsh',
      ['-NoProfile', '-Command', fullScript],
      environment: env,
      runInShell: false,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result;
  }

  @override
  Future<bool> ensureReady() async {
    if (!Platform.isWindows) return false;

    var pr = await _runPwsh(
        "Import-Module $_moduleName -ErrorAction Stop; Get-PSDrive DellSmbios -ErrorAction Stop | Out-Null");
    if (pr.exitCode == 0) return true;

    // Run prerequisites then install module
    const prereqScript = r'''
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13;
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) { Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null }
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue;
Install-Module -Name DellBIOSProvider -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop;
''';
    pr = await _runPwsh(prereqScript, includeTls: true);
    if (pr.exitCode != 0) return false;

    pr = await _runPwsh(
        "Import-Module $_moduleName -ErrorAction Stop; Get-PSDrive DellSmbios -ErrorAction Stop | Out-Null");
    return pr.exitCode == 0;
  }

  @override
  Future<bool> query(List<dynamic> queryParams, CCTKState cctkState, SharedPreferences? prefs) async {
    cctkState.exitCodeRead = 0;
    cctkState.cctkCompatible = true;
    final hasThermal = queryParams.any((p) => p.cmd == 'ThermalManagement');
    final hasBattery = queryParams.any((p) => p.cmd == 'PrimaryBattChargeCfg');
    if (!hasThermal && !hasBattery) return false;

    final script = StringBuffer(r'[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; Import-Module DellBIOSProvider; ');
    if (hasThermal) {
      script.write(r'Write-Output ((Get-Item "DellSmbios:\*\ThermalManagement" -EA SilentlyContinue).CurrentValue); ');
      for (var p in queryParams) if (p.cmd == 'ThermalManagement') cctkState.parameters[p]?.supported ??= _supportedModesFor('ThermalManagement');
    }
    if (hasBattery) {
      script.write(r'Write-Output ((Get-Item "DellSmbios:\*\PrimaryBattChargeCfg" -EA SilentlyContinue).CurrentValue); Write-Output ((Get-Item "DellSmbios:\*\CustomChargeStart" -EA SilentlyContinue).CurrentValue); Write-Output ((Get-Item "DellSmbios:\*\CustomChargeStop" -EA SilentlyContinue).CurrentValue)');
      for (var p in queryParams) if (p.cmd == 'PrimaryBattChargeCfg') cctkState.parameters[p]?.supported ??= _supportedModesFor('PrimaryBattChargeCfg');
    }
    final pr = await _runPwsh(script.toString(), includeTls: true);
    if (pr.exitCode != 0) {
      cctkState.exitCodeRead = pr.exitCode;
      return false;
    }
    final lines = pr.stdout.toString().trim().replaceAll('\r', '').split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    int idx = 0;
    if (hasThermal && idx < lines.length) {
      for (var param in queryParams) {
        if (param.cmd == 'ThermalManagement') {
          cctkState.parameters[param]?.mode = lines[idx];
          break;
        }
      }
      idx++;
    }
    if (hasBattery && idx < lines.length) {
      final mode = lines[idx++];
      String batteryMode = mode;
      if (mode == 'Custom' && idx + 1 < lines.length) {
        final start = lines[idx++];
        final stop = lines[idx++];
        batteryMode = 'Custom:$start:$stop';
      }
      for (var param in queryParams) {
        if (param.cmd == 'PrimaryBattChargeCfg') {
          cctkState.parameters[param]?.mode = batteryMode;
          break;
        }
      }
    }
    return true;
  }

  Map<String, bool> _supportedModesFor(String cmd) {
    if (cmd == 'ThermalManagement') {
      return {CCTK.thermalManagement.modes.optimized: true, CCTK.thermalManagement.modes.quiet: true, CCTK.thermalManagement.modes.cool: true, CCTK.thermalManagement.modes.ultra: true};
    }
    if (cmd == 'PrimaryBattChargeCfg') {
      return {
        CCTK.primaryBattChargeCfg.modes.standard: true,
        CCTK.primaryBattChargeCfg.modes.express: true,
        CCTK.primaryBattChargeCfg.modes.primAcUse: true,
        CCTK.primaryBattChargeCfg.modes.adaptive: true,
        CCTK.primaryBattChargeCfg.modes.custom: true,
      };
    }
    return {};
  }

  static String _psQuote(String s) => "'${s.replaceAll("'", "''")}'";

  @override
  Future<bool> request(String cctkType, String mode, CCTKState cctkState, {String? requestCode}) async {
    final requestId = requestCode ?? const Uuid().v4();
    String script;
    if (cctkType == 'ThermalManagement') {
      script = "Import-Module DellBIOSProvider; Set-Item \"DellSmbios:\\*\\ThermalManagement\" -Value ${_psQuote(mode)}";
      if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
      script += ' -ErrorAction Stop';
    } else if (cctkType == 'PrimaryBattChargeCfg') {
      if (mode.startsWith('Custom:') && mode.contains(':')) {
        final parts = mode.split(':');
        if (parts.length >= 3) {
          final start = parts[1];
          final stop = parts[2];
          script = "Import-Module DellBIOSProvider; Set-Item \"DellSmbios:\\*\\PrimaryBattChargeCfg\" -Value 'Custom'";
          if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
          script += "; Set-Item \"DellSmbios:\\*\\CustomChargeStart\" -Value $start";
          if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
          script += "; Set-Item \"DellSmbios:\\*\\CustomChargeStop\" -Value $stop";
          if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
          script += ' -ErrorAction Stop';
        } else {
          script = "Import-Module DellBIOSProvider; Set-Item \"DellSmbios:\\*\\PrimaryBattChargeCfg\" -Value ${_psQuote(mode)}";
          if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
          script += ' -ErrorAction Stop';
        }
      } else {
        script = "Import-Module DellBIOSProvider; Set-Item \"DellSmbios:\\*\\PrimaryBattChargeCfg\" -Value ${_psQuote(mode)}";
        if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
        script += ' -ErrorAction Stop';
      }
    } else {
      cctkState.exitStateWrite = ExitState(1, cctkType, mode, requestId);
      return false;
    }
    final pr = await _runPwsh(script, includeTls: true);
    int exitCode = pr.exitCode;
    final stderr = pr.stderr.toString();
    if (exitCode != 0 && stderr.isNotEmpty) {
      if (stderr.contains('password', caseSensitive: false) && stderr.contains('required', caseSensitive: false)) exitCode = 65;
      else if (stderr.contains('password', caseSensitive: false) && stderr.contains('invalid', caseSensitive: false)) exitCode = 67;
    }
    cctkState.exitStateWrite = ExitState(exitCode, cctkType, mode, requestId);
    cctkState.exitCodeRead = exitCode;
    return exitCode == 0;
  }
}
