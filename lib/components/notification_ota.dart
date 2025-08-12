import 'dart:async';
import 'dart:io';

import 'package:dell_powermanager/components/notification_item.dart';
import 'package:dell_powermanager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../classes/ota_manager.dart';
import '../configs/constants.dart';

enum OtaState {
  hidden,
  awaiting,
  downloading,
  installing,
  downloadFailed,
  installationFailed,
  installationSucceeded,
}

final Map<OtaState, NotificationState> mapStates = {
  OtaState.hidden                 : NotificationState.hidden,
  OtaState.awaiting               : NotificationState.present,
  OtaState.downloading            : NotificationState.loading,
  OtaState.installing             : NotificationState.loading,
  OtaState.downloadFailed         : NotificationState.failedLoading,
  OtaState.installationFailed     : NotificationState.failedLoading,
  OtaState.installationSucceeded  : NotificationState.succeeded,
};

class NotificationOta extends StatefulWidget {
  const NotificationOta({super.key});

  @override
  State<NotificationOta> createState() => NotificationOtaState();
}

class NotificationOtaState extends State<NotificationOta> {
  // assume running latest version by default
  OtaState _otaState = OtaState.hidden;
  // [tagname, releaseUrl, downloadUrl]
  List<String> _targetVersion = [];
  late Map<OtaState, String> otaStateTitles;

  @override
  void initState() {
    super.initState();
    OtaManager.addCallbacksOtaChanged(_handleOtaState);
    OtaManager.checkLatestOta().then((latestOta) => _handleOtaState(latestOta));
  }

  @override
  void dispose() {
    OtaManager.removeCallbacksOtaChanged(_handleOtaState);
    super.dispose();
  }

  void _handleOtaState(List<String> latestOta) {
    /* Update in progress */
    if (
      _otaState == OtaState.installationSucceeded ||
      _otaState == OtaState.installing ||
      _otaState == OtaState.downloading
    ) {
      return;
    }
    if (latestOta.length < 2 || !OtaManager.compareUpdateRequired(latestOta[0])) {
      setState(() {
        _otaState = OtaState.hidden;
      });
      return;
    }
    if (_otaState == OtaState.hidden) {
      setState(() {
        _targetVersion = latestOta;
        _otaState = OtaState.awaiting;
      });
    }
  }

  void _getOta() async {
    setState(() {
      _otaState = OtaState.downloading;
    });
    bool downloaded = await OtaManager.downloadOta(_targetVersion[0], _targetVersion[2]);
    if (!downloaded) {
      setState(() {
        _otaState = OtaState.downloadFailed;
      });
      return;
    }
    setState(() {
      _otaState = OtaState.installing;
    });
    bool installed = await OtaManager.installOta(_targetVersion[0]);
    setState(() {
      if (installed) {
        _otaState = OtaState.installationSucceeded;
      } else {
        _otaState = OtaState.installationFailed;
      }
    });
  }

  Future<void> _showDownloadModal() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context)!.otaCardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${S.of(context)!.otaAlertVersionCurrent}:\n${S.of(context)!.otaAlertVersionAvailable}:",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    "   ${Constants.applicationVersion}\n   ${_targetVersion[0]}",
                    style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!),
                  ),
                ],
              ),
              Text(
                "\n${S.of(context)!.otaAlertP1}",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.justify,
              ),
              _targetVersion.length > 2 ? Text(
                S.of(context)!.otaAlertP2,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.justify,
              ) : const SizedBox(),
            ],
          ),
          actions: <Widget>[
            TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              icon: const Icon(Icons.link_rounded),
              label: Text(S.of(context)!.otaAlertButtonRelease),
              onPressed: () {
                launchUrl(Uri.parse(_targetVersion[1]));
                Navigator.of(context).pop();
              },
            ),
            _targetVersion.length > 2 ? TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(S.of(context)!.otaAlertButtonInstall),
              onPressed: () {
                _getOta();
                Navigator.of(context).pop();
              },
            ) : const SizedBox(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    otaStateTitles = {
      OtaState.hidden                : "",
      OtaState.awaiting              : S.of(context)!.otaCardSubtitleAwaiting,
      OtaState.downloading           : S.of(context)!.otaCardSubtitleDownloading,
      OtaState.installing            : S.of(context)!.otaCardSubtitleInstalling,
      OtaState.downloadFailed        : S.of(context)!.otaCardSubtitleDownloadFailed,
      OtaState.installationFailed    : S.of(context)!.otaCardSubtitleInstallationFailed,
      OtaState.installationSucceeded : S.of(context)!.otaCardSubtitleInstallationSucceeded,
    };

    return NotificationItem(
      S.of(context)!.otaCardTitle,
      otaStateTitles[_otaState].toString(),
      Icons.browser_updated_rounded,
      state: mapStates[_otaState]!,
      onPress: () async {
        if (_otaState == OtaState.installing || _otaState == OtaState.downloading) {
          return;
        }
        if (_otaState == OtaState.installationSucceeded) {
          exit(0);
        }
        _showDownloadModal();
      },
    );
  }
}
