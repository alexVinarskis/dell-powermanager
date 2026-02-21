import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';

import '../classes/battery_state.dart';
import '../classes/battery.dart';
import '../configs/environment.dart';
import 'runtime_metrics.dart';

class ApiBattery {
  static final List<Duration> _additionalRefreshInternals = [];
  static const Duration _idleRefreshInternal = Duration(minutes: 1);
  static bool _hasSubscribers() => _callbacksStateChanged.isNotEmpty;
  static void _updateRefreshInterval() {
    final durations = <Duration>[..._additionalRefreshInternals, _initialRefreshInternal]..sort((a, b) => a.compareTo(b));
    var newMin = durations.first;
    if (!_hasSubscribers() && _additionalRefreshInternals.isEmpty && newMin < _idleRefreshInternal) {
      newMin = _idleRefreshInternal;
    }
    if (newMin != _refreshInternal) {
      _refreshInternal = newMin;
      requestUpdate();
    }
  }
  static void addQueryDuration(Duration interval) {
    _additionalRefreshInternals.add(interval);
    _updateRefreshInterval();
  }
  static void removeQueryDuration(Duration interval) {
    _additionalRefreshInternals.remove(interval);
    _updateRefreshInterval();
  }

  static final List<Function(BatteryState batteryState)> _callbacksStateChanged = [];
  static void addCallbacksStateChanged(var callback)  {
    _callbacksStateChanged.add(callback);
    _updateRefreshInterval();
    requestUpdate();
  }
  static void removeCallbacksStateChanged(var callback) {
    _callbacksStateChanged.remove(callback);
    _updateRefreshInterval();
  }

  static late Duration _initialRefreshInternal;
  static late Duration _refreshInternal;
  static late Timer _timer;
  static final _shell = Shell(verbose: Environment.runningDebug, throwOnError: false);

  static BatteryState? batteryState;

  ApiBattery(Duration refreshInternal) {
    _initialRefreshInternal = refreshInternal;
    _refreshInternal = _idleRefreshInternal;
    _query();
    _timer = Timer.periodic(_refreshInternal, (Timer t) => _query());
  }
  static void requestUpdate() {
    _timer.cancel();
    _query();
    _timer = Timer.periodic(_refreshInternal, (Timer t) => _query());
  }
  static void stop() {
    _timer.cancel();
  }

  static void _callStateChanged(BatteryState batteryState) {
    for (var callback in _callbacksStateChanged) {
      callback(batteryState);
    }
  }

  static Future<bool> _query() async {
    if (!_hasSubscribers() && _additionalRefreshInternals.isEmpty) {
      return false;
    }
    final startedMs = RuntimeMetrics.nowMs();
    // get response
    if (Platform.isLinux) {
      RuntimeMetrics.increment('process.batteryLinux');
      ProcessResult pr = (await _shell.run('''bash -c "${Battery.batteryInfoLinux.cmd}"'''))[0];
      if (!_processReponseLinux(pr)) {
        return false;
      }
    } else {
      RuntimeMetrics.increment('process.batteryWindows');
      ProcessResult pr = (await _shell.run(Battery.batteryInfoWindows.cmd))[0];
      if (!_processReponseWindows(pr)) {
        return false;
      }
    }
    // notify listeners
    _callStateChanged(batteryState!);
    RuntimeMetrics.logDuration('apiBattery.query', startedMs);
    return true;
  }
  static bool _processReponseLinux(ProcessResult pr) {
    if (pr.exitCode != 0) {
      return false;
    }
    Map<String, dynamic> map = {};
    List<String> lines = pr.stdout.toString().split("\n");
    for (String line in lines) {
      if (line.isEmpty) {
        continue;
      }
      List<String> parts = line.split("=");
      if (parts.length != 2) {
        continue;
      }
      map[parts[0]] = parts[1];
    }
    batteryState = BatteryState.fromLinuxMap(map);
    return true;
  }
  static bool _processReponseWindows(ProcessResult pr) {
     if (pr.exitCode != 0) {
      return false;
    }
    Map<String, dynamic> map = {};
    final lines = pr.stdout.toString().replaceAll("\r", "").split("\n");
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final colonSpace = trimmed.indexOf(": ");
      if (colonSpace <= 0) continue;
      map[trimmed.substring(0, colonSpace).trim()] = trimmed.substring(colonSpace + 2).trim();
    }
    batteryState = BatteryState.fromWindowsMap(map);
    return true;
  }
}
