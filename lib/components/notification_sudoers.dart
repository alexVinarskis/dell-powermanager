import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../classes/api_cctk.dart';
import '../configs/constants.dart';
import '../classes/sudoers_manager.dart';

enum SudoersState {
  hidden,
  awaiting,
  patching,
  patchingFailed,
  patchingSucceededRestart,
  patchingSucceededNoRestart,
}

class NotificationSudoers extends StatefulWidget {
  const NotificationSudoers({super.key, this.paddingH = 0, this.paddingV = 0, this.backgroundColor = Colors.transparent});

  final double paddingH;
  final double paddingV;
  final Color backgroundColor;

  @override
  State<NotificationSudoers> createState() => NotificationSudoersState();
}

class NotificationSudoersState extends State<NotificationSudoers> {
  SudoersState _sudoersState = SudoersState.hidden;
  late Map<SudoersState, String> sudoersStateTitles;

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
    if (!apiReady) {
      return;
    }
    SudoersManager.verifySudo().then((runningSudo) => _handleSudoersState(runningSudo));
  }

  void _handleSudoersState(bool runningSudo) {
    if (runningSudo) {
      return;
    }
    setState(() {
      _sudoersState = SudoersState.awaiting;
    });
    ApiCCTK.removeCallbacksDepsChanged(_handleApiStateUpdate);
  }

  void _patchSudoers() async {
    setState(() {
      _sudoersState = SudoersState.patching;
    });
    bool patched = await SudoersManager.patchSudoers();
    if (patched) {
      setState(() {
        _sudoersState = SudoersState.patchingSucceededNoRestart;
      });
      bool runningSudo = await SudoersManager.verifySudo();
      if (runningSudo) {
        ApiCCTK.requestUpdate();
        Timer(const Duration(seconds: 3), () {
          setState(() {
            _sudoersState = SudoersState.hidden;
          });
        });
      } else {
        setState(() {
          _sudoersState = SudoersState.patchingSucceededRestart;
        });
      }
    } else {
      setState(() {
        _sudoersState = SudoersState.patchingFailed;
      });
    }
  }

  Widget _getProgressBar(var state, BuildContext context) {
    switch (state) {
      case SudoersState.patching:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent);
      case SudoersState.patchingFailed:
        return LinearProgressIndicator(backgroundColor: Colors.transparent, color: Theme.of(context).colorScheme.error, value: 1,);
      case SudoersState.patchingSucceededRestart:
      case SudoersState.patchingSucceededNoRestart:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.green, value: 1,);
      default:
        return  const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.transparent,);
    }
  }

  Widget _getIcon(var state, BuildContext context) {
    switch (state) {
      case SudoersState.patchingFailed:
        return Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error,);
      case SudoersState.patchingSucceededRestart:
      case SudoersState.patchingSucceededNoRestart:
        return const Icon(Icons.check_circle_outline_outlined, color: Colors.green,);
      default:
        return const Icon(Icons.security_rounded);
    }
  }

  Future<void> _showPatchModal() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context)!.sudoersAlertTitle),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${S.of(context)!.sudoersAlertP1}\n",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        SudoersManager.sudoersPatchCmd,
                        style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!),
                      ),
                    ),
                  )
                ),
                Text(
                  "\n\n${S.of(context)!.sudoersAlertP2}",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(S.of(context)!.sudoersAlertButtonPatch),
              onPressed: () {
                _patchSudoers();
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
    sudoersStateTitles = {
      SudoersState.hidden                     : "",
      SudoersState.awaiting                   : Platform.isLinux ? S.of(context)!.sudoersCardSubtitleAwaiting : S.of(context)!.adminCardSubtitleAwaiting,
      SudoersState.patching                   : S.of(context)!.sudoersCardSubtitlePatching,
      SudoersState.patchingFailed             : S.of(context)!.sudoersCardSubtitlePatchingFailed,
      SudoersState.patchingSucceededRestart   : S.of(context)!.sudoersCardSubtitlePatchingSucceededRestart,
      SudoersState.patchingSucceededNoRestart : S.of(context)!.sudoersCardSubtitlePatchingSucceededNoRestart,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: Constants.animationMs),
      child:  _sudoersState != SudoersState.hidden ? Card(
        key: const Key("sudoersShownTrue"),
        clipBehavior: Clip.antiAlias,
        color: Colors.amber.withOpacity(0.4),
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: widget.paddingV, horizontal: widget.paddingH),
        child: InkWell(
          onTap: () async {
            if (_sudoersState == SudoersState.patchingSucceededRestart) {
              exit(0);
            }
            if (_sudoersState == SudoersState.patching || _sudoersState == SudoersState.patchingSucceededNoRestart) {
              return;
            }
            if (!Platform.isLinux) {
              return;
            }
            _showPatchModal();
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: _getIcon(_sudoersState, context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Platform.isLinux ? S.of(context)!.sudoersCardTitle : S.of(context)!.adminCardTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5,),
                        Text(sudoersStateTitles[_sudoersState].toString(), textAlign: TextAlign.justify,),
                      ],
                    ),
                  ),
                ],
              ),
              Align(alignment: Alignment.bottomCenter, child: _getProgressBar(_sudoersState, context),),
            ],
          ),
        ),
      ) : const SizedBox(
        key: Key("sudoersShownFalse"),
      ),
    );
  }
}
