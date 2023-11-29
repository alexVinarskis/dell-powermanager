import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';

import '../classes/battery_state.dart';
import '../classes/battery.dart';

class ApiBattery {
  static final List<Duration> _additionalRefreshInternals = [];
  static void addQueryDuration(Duration interval) {
    _additionalRefreshInternals.add(interval);
    List durations = {..._additionalRefreshInternals, _initialRefreshInternal}.toList();
    durations.sort(((a, b) => a.compareTo(b)));
    _refreshInternal = durations[0];
    requestUpdate();
  }
  static void removeQueryDuration(Duration interval) {
    _additionalRefreshInternals.remove(interval);
    List durations = {..._additionalRefreshInternals, _initialRefreshInternal}.toList();
    durations.sort(((a, b) => a.compareTo(b)));
    _refreshInternal = durations[0];
    requestUpdate();
  }

  static final List<Function(BatteryState batteryState)> _callbacksStateChanged = [];
  static void addCallbacksStateChanged(var callback)  { _callbacksStateChanged.add(callback); }
  static void removeCallbacksStateChanged(var callback) { _callbacksStateChanged.remove(callback); }

  static late Duration _initialRefreshInternal;
  static late Duration _refreshInternal;
  static late Timer _timer;
  static final _shell = Shell(throwOnError: false);

  static BatteryState? batteryState;

  ApiBattery(Duration refreshInternal) {
    _initialRefreshInternal = refreshInternal;
    _refreshInternal = _initialRefreshInternal;
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
    // get response
    if (Platform.isLinux) {
      ProcessResult pr = (await _shell.run(Battery.batteryInfoLinux.cmd))[0];
      if (!_processReponseLinux(pr)) {
        return false;
      }
    } else {
      ProcessResult pr = (await _shell.run(Battery.batteryInfoWindows.cmd))[0];
      if (!_processReponseWindows(pr)) {
        return false;
      }
    }
    // notify listeners
    _callStateChanged(batteryState!);
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
    List<String> lines = pr.stdout.toString().split("\n");
    for (String line in lines) {
      if (line.isEmpty) {
        continue;
      }
      List<String> parts = line.replaceAll("\r", "").split(": ");
      if (parts.length != 2) {
        continue;
      }
      map[parts[0].trim()] = parts[1].trim();
    }
    batteryState = BatteryState.fromWindowsMap(map);
    return true;
  }
}
