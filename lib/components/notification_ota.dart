import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

class NotificationOta extends StatefulWidget {
  const NotificationOta({super.key, this.paddingH = 0, this.paddingV = 0, this.backgroundColor = Colors.transparent});

  final double paddingH;
  final double paddingV;
  final Color backgroundColor;

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
    OtaManager.checkLatestOta().then((latestOta) => _handleOtaState(latestOta));
  }

  void _handleOtaState(List<String> latestOta) {
    if (latestOta.length < 2) {
      return;
    }
    if (!OtaManager.compareUpdateRequired(latestOta[0])) {
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

  Widget _getProgressBar(var state, BuildContext context) {
    switch (state) {
      case OtaState.installing:
      case OtaState.downloading:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent);
      case OtaState.installationFailed:
      case OtaState.downloadFailed:
        return LinearProgressIndicator(backgroundColor: Colors.transparent, color: Theme.of(context).colorScheme.error, value: 1,);
      case OtaState.installationSucceeded:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.green, value: 1,);
      default:
        return  const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.transparent,);
    }
  }

  Widget _getIcon(var state, BuildContext context) {
    switch (state) {
      case OtaState.installationFailed:
      case OtaState.downloadFailed:
        return Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error,);
      case OtaState.installationSucceeded:
        return const Icon(Icons.check_circle_outline_outlined, color: Colors.green,);
      default:
        return const Icon(Icons.browser_updated_rounded);
    }
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: Constants.animationMs),
      child:  _otaState != OtaState.hidden ? Card(
        key: const Key("otaAvailableTrue"),
        clipBehavior: Clip.antiAlias,
        color: Colors.amber.withOpacity(0.4),
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: widget.paddingV, horizontal: widget.paddingH),
        child: InkWell(
          onTap: () async {
            if (_otaState == OtaState.installing || _otaState == OtaState.downloading) {
              return;
            }
            if (_otaState == OtaState.installationSucceeded) {
              exit(0);
            }
            _showDownloadModal();
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: _getIcon(_otaState, context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context)!.otaCardTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5,),
                        Text(otaStateTitles[_otaState].toString(), textAlign: TextAlign.justify,),
                      ],
                    ),
                  ),
                ],
              ),
              Align(alignment: Alignment.bottomCenter, child: _getProgressBar(_otaState, context),),
            ],
          ),
        ),
      ) : const SizedBox(
        key: Key("otaAvailableFalse"),
      ),
    );
  }
}
