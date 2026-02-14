import 'dart:async';
import 'dart:io';

import 'package:dell_powermanager/components/notification_item.dart';
import 'package:dell_powermanager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../configs/constants.dart';
import '../classes/api_cctk.dart';
import '../classes/dependencies_manager.dart';

enum DependenciesState {
  hidden,
  awaiting,
  downloading,
  installing,
  downloadFailed,
  installationFailed,
  installationSucceeded,
}

final Map<DependenciesState, NotificationState> mapStates = {
  DependenciesState.hidden                 : NotificationState.hidden,
  DependenciesState.awaiting               : NotificationState.present,
  DependenciesState.downloading            : NotificationState.loading,
  DependenciesState.installing             : NotificationState.loading,
  DependenciesState.downloadFailed         : NotificationState.failedLoading,
  DependenciesState.installationFailed     : NotificationState.failedLoading,
  DependenciesState.installationSucceeded  : NotificationState.succeeded,
};

class NotificationDependencies extends StatefulWidget {
  const NotificationDependencies({super.key});

  @override
  State<NotificationDependencies> createState() => NotificationDependenciesState();
}

class NotificationDependenciesState extends State<NotificationDependencies> {
  // assume all dependencies are installed by default
  DependenciesState _dependenciesState = DependenciesState.hidden;
  late Map<DependenciesState, String> dependenciesStateTitles;

  @override
  void initState() {
    super.initState();
    ApiCCTK.addCallbacksDepsChanged(_handleApiStateUpdate);
  }

  @override
  void dispose() {
    ApiCCTK.removeCallbacksDepsChanged(_handleApiStateUpdate);
    super.dispose();
  }

  void _handleApiStateUpdate(bool apiReady) {
    if (!apiReady && _dependenciesState == DependenciesState.hidden) {
      setState(() {
        _dependenciesState = DependenciesState.awaiting;
      });
    }
    if (apiReady) {
      Timer(const Duration(seconds: 3), () {
        setState(() {
          _dependenciesState = DependenciesState.hidden;
        });
      });
      ApiCCTK.removeCallbacksDepsChanged(_handleApiStateUpdate);
    }
  }

  void _getDependencies() async {
    setState(() {
      _dependenciesState = DependenciesState.downloading;
    });
    bool downloaded = await DependenciesManager.downloadDependencies();
    if (!downloaded) {
      setState(() {
        _dependenciesState = DependenciesState.downloadFailed;
      });
      return;
    }
    setState(() {
      _dependenciesState = DependenciesState.installing;
    });
    bool installed = await DependenciesManager.installDependencies();
    setState(() {
      if (installed) {
        _dependenciesState = DependenciesState.installationSucceeded;
      } else {
        _dependenciesState = DependenciesState.installationFailed;
      }
    });
  }

  Future<void> _showDownloadModal() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        if (Platform.isWindows) {
          return AlertDialog(
            title: Text(S.of(context)!.dependenciesCardTitle),
            content: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: S.of(context)!.dependenciesAlertWindowsP1,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const TextSpan(text: '\n\n'),
                  TextSpan(
                    text: S.of(context)!.dependenciesAlertWindowsP2,
                    style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                icon: const Icon(Icons.link_rounded),
                label: Text(S.of(context)!.dependenciesAlertButtonOpenGuide),
                onPressed: () {
                  launchUrl(Uri.parse(Constants.urlDellBiosProvider));
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
        return AlertDialog(
          title: Text(S.of(context)!.dependenciesCardTitle),
          content: RichText(
            text: TextSpan(
              children: [
                TextSpan(text:
                  S.of(context)!.dependenciesAlertP1,
                  style: Theme.of(context).textTheme.bodyMedium
                ),
                TextSpan(text: ' "${S.of(context)!.dependenciesAlertP2}" ', style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!)),
                TextSpan(text:
                  S.of(context)!.dependenciesAlertP3,
                  style: Theme.of(context).textTheme.bodyMedium
                ),
                TextSpan(text: Constants.packagesLinux.join('\n'), style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!)),
                TextSpan(text:
                  '\n\n',
                  style: Theme.of(context).textTheme.bodyMedium
                ),
                TextSpan(text:
                  DependenciesManager.supportsAutoinstall ?? false ? S.of(context)!.dependenciesAlertP4_supported : S.of(context)!.dependenciesAlertP4_unsupported,
                  style: Theme.of(context).textTheme.bodyMedium
                ),
              ],
            ),
          ),
          actions: <Widget>[
            DependenciesManager.supportsAutoinstall ?? false ? TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(S.of(context)!.dependenciesAlertButton_supported),
              onPressed: () {
                _getDependencies();
                Navigator.of(context).pop();
              },
            ) : TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              icon: const Icon(Icons.link_rounded),
              label: Text(S.of(context)!.dependenciesAlertButton_unsupported),
              onPressed: () {
                launchUrl(Uri.parse(Constants.urlDellCommandConfigure));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    dependenciesStateTitles = {
      DependenciesState.hidden                : "",
      DependenciesState.awaiting              : S.of(context)!.dependenciesCardSubtitleAwaiting,
      DependenciesState.downloading           : S.of(context)!.dependenciesCardSubtitleDownloading,
      DependenciesState.installing            : S.of(context)!.dependenciesCardSubtitleInstalling,
      DependenciesState.downloadFailed        : S.of(context)!.dependenciesCardSubtitleDownloadFailed,
      DependenciesState.installationFailed    : S.of(context)!.dependenciesCardSubtitleInstallationFailed,
      DependenciesState.installationSucceeded : S.of(context)!.dependenciesCardSubtitleInstallationSucceeded,
    };

    return NotificationItem(
      S.of(context)!.dependenciesCardTitle,
      dependenciesStateTitles[_dependenciesState].toString(),
      Icons.warning_amber_rounded,
      state: mapStates[_dependenciesState]!,
      onPress: () {
        if (_dependenciesState == DependenciesState.installing || _dependenciesState == DependenciesState.downloading) {
          return;
        }
        _showDownloadModal();
      },
    );
  }
}
