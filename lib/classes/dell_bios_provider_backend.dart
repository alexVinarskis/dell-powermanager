import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../configs/constants.dart';
import '../configs/environment.dart';
import 'bios_backend.dart';
import 'cctk.dart';
import 'cctk_state.dart';
import 'runtime_metrics.dart';

/// BIOS backend using DellBIOSProvider PowerShell module (Windows only).
class DellBiosProviderBackend implements BiosBackend {
  DellBiosProviderBackend(this._shell);

  final Shell _shell;
  static const _moduleName = 'DellBIOSProvider';
  static const _importAndDriveCheck = 'Import-Module DellBIOSProvider -ErrorAction Stop; Get-PSDrive DellSmbios -ErrorAction Stop | Out-Null';
  Process? _pwshSession;
  StreamSubscription<String>? _pwshStdoutSub;
  StreamSubscription<String>? _pwshStderrSub;
  final List<String> _stdoutLines = [];
  final List<String> _stderrLines = [];
  Completer<void>? _lineSignal;
  String? _sessionBiosPwd;

  @override
  void sourceEnvironment(Shell shell) {
    // Session env must be rebuilt when BIOS_PWD changes.
    unawaited(_invalidateSession());
  }

  Future<ProcessResult> _runPwsh(String script, {bool includeTls = false}) async {
    RuntimeMetrics.increment('process.pwsh');
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

  Future<void> _invalidateSession() async {
    await _pwshStdoutSub?.cancel();
    await _pwshStderrSub?.cancel();
    _pwshStdoutSub = null;
    _pwshStderrSub = null;
    final process = _pwshSession;
    _pwshSession = null;
    _stdoutLines.clear();
    _stderrLines.clear();
    _sessionBiosPwd = null;
    _lineSignal?.complete();
    _lineSignal = null;
    process?.kill(ProcessSignal.sigterm);
  }

  Future<void> _ensureSession() async {
    final currentPwd = Environment.biosPwd;
    if (_pwshSession != null && _sessionBiosPwd == currentPwd) {
      return;
    }
    await _invalidateSession();
    RuntimeMetrics.increment('process.pwshSessionStart');
    final env = <String, String>{...Platform.environment};
    if (currentPwd != null) env[Constants.varnameBiosPwd] = currentPwd;
    final process = await Process.start(
      'pwsh',
      ['-NoLogo', '-NoProfile', '-Command', '-'],
      environment: env,
      runInShell: false,
    );
    _pwshSession = process;
    _sessionBiosPwd = currentPwd;
    _lineSignal = Completer<void>();
    _pwshStdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _stdoutLines.add(line);
      if (!(_lineSignal?.isCompleted ?? true)) {
        _lineSignal?.complete();
      }
    });
    _pwshStderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _stderrLines.add(line);
      if (!(_lineSignal?.isCompleted ?? true)) {
        _lineSignal?.complete();
      }
    });
  }

  Future<void> _awaitMarker(String marker, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_stdoutLines.any((l) => l == marker)) return;
      _lineSignal = Completer<void>();
      try {
        await _lineSignal!.future.timeout(const Duration(milliseconds: 200));
      } catch (_) {
        // timeout tick, continue polling until deadline
      }
    }
    throw TimeoutException('PowerShell session command timed out');
  }

  Future<ProcessResult> _runPwshSession(String script, {Duration timeout = const Duration(seconds: 40)}) async {
    await _ensureSession();
    final marker = '__CURSOR_DONE_${const Uuid().v4()}__';
    final wrapped = '''
\$ErrorActionPreference = 'Stop'
try {
$script
  [Console]::Out.WriteLine('$marker' + '0')
} catch {
  [Console]::Error.WriteLine(\$_.Exception.Message)
  [Console]::Out.WriteLine('$marker' + '1')
}
''';
    final session = _pwshSession;
    if (session == null) {
      throw StateError('PowerShell session unavailable');
    }
    final stdoutStart = _stdoutLines.length;
    final stderrStart = _stderrLines.length;
    session.stdin.writeln(wrapped);
    await session.stdin.flush();
    await _awaitMarker('$marker' '0', timeout).catchError((_) async {
      await _awaitMarker('$marker' '1', timeout);
    });

    int exitCode = 1;
    final outputSlice = _stdoutLines.sublist(stdoutStart);
    final errorSlice = _stderrLines.sublist(stderrStart);
    final markerIndex = outputSlice.indexWhere((line) => line.startsWith(marker));
    if (markerIndex >= 0) {
      final markerLine = outputSlice[markerIndex];
      exitCode = markerLine.endsWith('0') ? 0 : 1;
      outputSlice.removeRange(markerIndex, outputSlice.length);
      final consumedStdout = stdoutStart + markerIndex + 1;
      if (consumedStdout > 0 && consumedStdout <= _stdoutLines.length) {
        _stdoutLines.removeRange(0, consumedStdout);
      }
    }
    _stderrLines.clear();
    return ProcessResult(
      session.pid,
      exitCode,
      outputSlice.join('\n'),
      errorSlice.join('\n'),
    );
  }

  @override
  Future<bool> ensureReady() async {
    final startedMs = RuntimeMetrics.nowMs();
    if (!Platform.isWindows) return false;

    var pr = await _runPwshSession(_importAndDriveCheck).catchError((_) => _runPwsh(_importAndDriveCheck));
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

    await _invalidateSession();
    pr = await _runPwshSession(_importAndDriveCheck).catchError((_) => _runPwsh(_importAndDriveCheck));
    RuntimeMetrics.logDuration('dellBiosProvider.ensureReady', startedMs, extra: 'exit=${pr.exitCode}');
    return pr.exitCode == 0;
  }

  @override
  Future<bool> query(List<dynamic> queryParams, CCTKState cctkState, SharedPreferences? prefs) async {
    final startedMs = RuntimeMetrics.nowMs();
    cctkState.exitCodeRead = 0;
    cctkState.cctkCompatible = true;
    final hasThermal = queryParams.any((p) => p.cmd == 'ThermalManagement');
    final hasBattery = queryParams.any((p) => p.cmd == 'PrimaryBattChargeCfg');
    if (!hasThermal && !hasBattery) return false;

    final script = StringBuffer(r'Import-Module DellBIOSProvider; ');
    if (hasThermal) {
      script.write(r'Write-Output ((Get-Item "DellSmbios:\*\ThermalManagement" -EA SilentlyContinue).CurrentValue); ');
      for (var p in queryParams) if (p.cmd == 'ThermalManagement') cctkState.parameters[p]?.supported ??= _supportedModesFor('ThermalManagement');
    }
    if (hasBattery) {
      script.write(r'Write-Output ((Get-Item "DellSmbios:\*\PrimaryBattChargeCfg" -EA SilentlyContinue).CurrentValue); Write-Output ((Get-Item "DellSmbios:\*\CustomChargeStart" -EA SilentlyContinue).CurrentValue); Write-Output ((Get-Item "DellSmbios:\*\CustomChargeStop" -EA SilentlyContinue).CurrentValue)');
      for (var p in queryParams) if (p.cmd == 'PrimaryBattChargeCfg') cctkState.parameters[p]?.supported ??= _supportedModesFor('PrimaryBattChargeCfg');
    }
    final pr = await _runPwshSession(script.toString()).catchError((_) => _runPwsh(script.toString()));
    if (pr.exitCode != 0) {
      cctkState.exitCodeRead = pr.exitCode;
      RuntimeMetrics.logDuration('dellBiosProvider.query.failed', startedMs, extra: 'exit=${pr.exitCode}');
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
    RuntimeMetrics.logDuration('dellBiosProvider.query', startedMs, extra: 'thermal=$hasThermal battery=$hasBattery');
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
    final startedMs = RuntimeMetrics.nowMs();
    final requestId = requestCode ?? const Uuid().v4();
    String script;
    if (cctkType == 'ThermalManagement') {
      script = "Import-Module DellBIOSProvider; Set-Item \"DellSmbios:\\*\\ThermalManagement\" -Value ${_psQuote(mode)}";
      if (Environment.biosPwd != null) script += " -Password \$env:${Constants.varnameBiosPwd}";
      script += ' -ErrorAction Stop';
    } else if (cctkType == 'PrimaryBattChargeCfg') {
      if (mode.startsWith('Custom:') && mode.contains(':')) {
        final parts = mode.split(':');
        String? start;
        String? stop;
        if (parts.length >= 3) {
          start = parts[1];
          stop = parts[2];
        } else if (parts.length == 2 && parts[1].contains('-')) {
          final range = parts[1].split('-');
          if (range.length >= 2) {
            start = range[0].trim();
            stop = range[1].trim();
          }
        }
        if (start != null && stop != null) {
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
    final pr = await _runPwshSession(script).catchError((_) => _runPwsh(script));
    int exitCode = pr.exitCode;
    final stderr = pr.stderr.toString();
    if (exitCode != 0 && stderr.isNotEmpty) {
      final stderrLower = stderr.toLowerCase();
      if (stderrLower.contains('password') && stderrLower.contains('required')) exitCode = 65;
      else if (stderrLower.contains('password') && stderrLower.contains('invalid')) exitCode = 67;
    }
    cctkState.exitStateWrite = ExitState(exitCode, cctkType, mode, requestId);
    cctkState.exitCodeRead = exitCode;
    RuntimeMetrics.logDuration('dellBiosProvider.request', startedMs, extra: 'type=$cctkType exit=$exitCode');
    return exitCode == 0;
  }
}
