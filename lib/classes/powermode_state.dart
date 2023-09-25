import '../classes/powermode.dart';

class PowermodeState {
  PowermodeProfile? profileInfo;

  PowermodeState.fromLinuxResponse(String response) {
    profileInfo = _setIfPresent(response, (var x) => Powermode.profileInfoLinux.map.containsKey(x) ? Powermode.profileInfoLinux.map[x] : null);
  }
  PowermodeState.fromWindowsResponse(Map<String, dynamic> map) {
    // ToDo Windows integration;
  }

  _setIfPresent(var source, var transformation) {
    if (source == null || source.isEmpty) {
      return null;
    }
    return transformation(source);
  }
}
