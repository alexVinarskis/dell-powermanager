import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';

import '../classes/powermode_state.dart';
import '../classes/powermode.dart';

class ApiPowermode {
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

  static final List<Function(PowermodeState powermodeState)> _callbacksStateChanged = [];
  static void addCallbacksStateChanged(var callback)  { _callbacksStateChanged.add(callback); }
  static void removeCallbacksStateChanged(var callback) { _callbacksStateChanged.remove(callback); }

  static late Duration _initialRefreshInternal;
  static late Duration _refreshInternal;
  static late Timer _timer;
  static final _shell = Shell(throwOnError: false);

  static PowermodeState? powermodeState;

  ApiPowermode(Duration refreshInternal) {
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

  static void _callStateChanged(PowermodeState powermodeState) {
    for (var callback in _callbacksStateChanged) {
      callback(powermodeState);
    }
  }

  static Future<bool> _query() async {
    // get response
    if (Platform.isLinux) {
      ProcessResult pr = (await _shell.run(Powermode.profileInfoLinux.cmd))[0];
      if (!_processReponseLinux(pr)) {
        return false;
      }
    } else {
      ProcessResult pr = (await _shell.run(Powermode.profileInfoWindows.cmd))[0];
      if (!_processReponseWindows(pr)) {
        return false;
      }
    }
    // notify listeners
    _callStateChanged(powermodeState!);
    return true;
  }

  static bool _processReponseLinux(ProcessResult pr) {
    if (pr.exitCode != 0) {
      return false;
    }
    powermodeState = PowermodeState.fromLinuxResponse(pr.stdout.toString().trim().replaceAll("\n", ""));
    return true;
  }
  static bool _processReponseWindows(ProcessResult pr) {
    if (pr.exitCode != 0) {
      return false;
    }
    powermodeState = PowermodeState.fromWindowsResponse(pr.stdout.toString().trim().replaceAll("\n", ""));
    return true;
  }
}
