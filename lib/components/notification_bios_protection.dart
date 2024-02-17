import 'dart:async';
import 'dart:io';

import 'package:dell_powermanager/classes/cctk.dart';
import 'package:dell_powermanager/components/notification_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:passwordfield/passwordfield.dart';
import '../classes/api_cctk.dart';
import '../classes/bios_protection_manager.dart';
import '../classes/cctk_state.dart';

enum BiosProtectionState {
  hidden,
  missingSysPwd,
  missingSetupPwd,
  enforcedOwnerPwd,
  unlocking,
  unlockingSucceeded,
  unlockingSysPwdFailed,
  unlockingSetupPwdFailed,
}

final Map<BiosProtectionState, NotificationState> mapStates = {
  BiosProtectionState.hidden                  : NotificationState.hidden,
  BiosProtectionState.missingSetupPwd         : NotificationState.present,
  BiosProtectionState.missingSysPwd           : NotificationState.present,
  BiosProtectionState.enforcedOwnerPwd        : NotificationState.present,
  BiosProtectionState.unlocking               : NotificationState.loading,
  BiosProtectionState.unlockingSysPwdFailed   : NotificationState.failedLoading,
  BiosProtectionState.unlockingSetupPwdFailed : NotificationState.failedLoading,
  BiosProtectionState.unlockingSucceeded      : NotificationState.succeeded,
};

class NotificationBiosProtection extends StatefulWidget {
  const NotificationBiosProtection({super.key});

  @override
  State<NotificationBiosProtection> createState() => NotificationBiosProtectionState();
}

class NotificationBiosProtectionState extends State<NotificationBiosProtection> {
  BiosProtectionState _biosProtectionState = BiosProtectionState.hidden;
  late Map<BiosProtectionState, String> biosProtectionStateSubtitles;
  final FocusNode modalButtonFocusNode = FocusNode();
  final TextEditingController modalPwdController = TextEditingController();
  bool _savingPwd = false;

  @override
  void initState() {
    super.initState();
    ApiCCTK.addCallbacksStateChanged(_handleCCTKStateUpdate);
  }

  @override
  void dispose() {
    modalButtonFocusNode.dispose();
    modalPwdController.dispose();
    ApiCCTK.removeCallbacksStateChanged(_handleCCTKStateUpdate);
    super.dispose();
  }

  void _handleCCTKStateUpdate(CCTKState cctkState) {
    if (cctkState.exitStateWrite == null) {
      return;
    }

    /* Once succeeded, exit */
    if (cctkState.exitStateWrite!.exitCode == CCTK.exitCodes.ok) {
      if (_biosProtectionState == BiosProtectionState.unlocking) {
        /* Was unlocking, and it worked */
        setState(() {
          _biosProtectionState = BiosProtectionState.unlockingSucceeded;
        });
        Timer(const Duration(seconds: 3), () {
          setState(() {
            _biosProtectionState = BiosProtectionState.hidden;
          });
        });
      } else {
        /* Was _not_ unlocking, bios writable already OR password was just removed */
        setState(() {
          _biosProtectionState = BiosProtectionState.hidden;
        });
      }
      ApiCCTK.removeCallbacksStateChanged(_handleCCTKStateUpdate);
      return;
    }

    /* Ignore state, if issue was already detected */
    if (
      _biosProtectionState == BiosProtectionState.unlockingSucceeded ||
      _biosProtectionState == BiosProtectionState.unlockingSysPwdFailed ||
      _biosProtectionState == BiosProtectionState.unlockingSetupPwdFailed ||
      _biosProtectionState == BiosProtectionState.missingSetupPwd ||
      _biosProtectionState == BiosProtectionState.missingSysPwd
      ) {
        return;
    }

    if (cctkState.exitStateWrite!.exitCode == CCTK.exitCodes.sysPwdInvalid) {
      setState(() {
        _biosProtectionState = BiosProtectionState.unlockingSysPwdFailed;
      });
    } else if (
      cctkState.exitStateWrite!.exitCode == CCTK.exitCodes.setupPwdInvalid) {
      setState(() {
        _biosProtectionState = BiosProtectionState.unlockingSetupPwdFailed;
      });
    } else if (cctkState.exitStateWrite!.exitCode == CCTK.exitCodes.sysPwdRequired) {
      setState(() {
        _biosProtectionState = _biosProtectionState == BiosProtectionState.unlocking ? BiosProtectionState.unlockingSysPwdFailed : BiosProtectionState.missingSysPwd;
      });
    } else if (cctkState.exitStateWrite!.exitCode == CCTK.exitCodes.setupPwdRequired) {
      setState(() {
        _biosProtectionState = _biosProtectionState == BiosProtectionState.unlocking ? BiosProtectionState.unlockingSetupPwdFailed : BiosProtectionState.missingSetupPwd;
      });
    } else if (cctkState.exitStateWrite!.exitCode == CCTK.exitCodes.ownerPwdSet) {
      setState(() {
        _biosProtectionState = BiosProtectionState.enforcedOwnerPwd;
      });
    }
  }

  Future<void> _showRequestPwdModal(String title, String p1, String hint) {
    modalPwdController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 450,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) { 
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p1,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.justify,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5, right: 5, top: 30, bottom: 25),
                      child: PasswordField(
                        color: Theme.of(context).colorScheme.primary,
                        passwordConstraint: r'^\S+$',
                        passwordDecoration: PasswordDecoration(),
                        controller: modalPwdController,
                        hintText: hint,
                        autoFocus: true,
                        onSubmit: (text) => {
                          modalButtonFocusNode.requestFocus(),
                        },
                        border: PasswordBorder(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              width: 2,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        errorMessage: S.of(context)!.biosProtectionAlertRequiredPwdErrorMsg,
                      ),
                    ),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      elevation: 0,
                      margin: const EdgeInsets.only(left: 5, right: 5),
                      child: InkWell(
                      onTap: () {
                        setState(() {
                          _savingPwd = !_savingPwd;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _savingPwd,
                              onChanged: (bool? value) {
                                setState(() {
                                  _savingPwd = value!;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    S.of(context)!.biosProtectionAlertRequiredPwdSavePwdTitle,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Container(
                                  width: 360,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Platform.isLinux ? S.of(context)!.biosProtectionAlertRequiredPwdSavePwdDisclaimerLinux : S.of(context)!.biosProtectionAlertRequiredPwdSavePwdDisclaimerWindows,
                                    textAlign: TextAlign.justify,
                                    style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ), 
                    ),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              focusNode: modalButtonFocusNode,
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(S.of(context)!.biosProtectionAlertRequiredPwdButton),
              onPressed: () async {
                Navigator.of(context).pop();
                final String enteredPwd = modalPwdController.text;
                if (enteredPwd.isNotEmpty) {
                  BiosProtectionManager.loadPassword(enteredPwd);
                  if (_savingPwd) {
                    BiosProtectionManager.secureWritePassword(enteredPwd);
                  }
                  ApiCCTK.request(ApiCCTK.cctkState.exitStateWrite!.cctkType, ApiCCTK.cctkState.exitStateWrite!.mode);
                  setState(() {
                    _biosProtectionState = BiosProtectionState.unlocking;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEnforcedOwnerPwdModal() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context)!.biosProtectionAlertOwnerPwdTitle),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${S.of(context)!.biosProtectionAlertOwnerP1}\n\n",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
                Text(
                  S.of(context)!.biosProtectionAlertOwnerP2,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              autofocus: true,
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(S.of(context)!.biosProtectionAlertOwnerPwdButton),
              onPressed: () {
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
    biosProtectionStateSubtitles = {
      BiosProtectionState.hidden                  : "",
      BiosProtectionState.missingSysPwd           : S.of(context)!.biosProtectionCardSubtitileMissingSysPwd,
      BiosProtectionState.missingSetupPwd         : S.of(context)!.biosProtectionCardSubtitileMissingSetupPwd,
      BiosProtectionState.enforcedOwnerPwd        : S.of(context)!.biosProtectionCardSubtitileEnforcedOwnerPwd,
      BiosProtectionState.unlocking               : S.of(context)!.biosProtectionCardSubtitileUnlocking,
      BiosProtectionState.unlockingSysPwdFailed   : S.of(context)!.biosProtectionCardSubtitileUnlockingFailed,
      BiosProtectionState.unlockingSetupPwdFailed : S.of(context)!.biosProtectionCardSubtitileUnlockingFailed,
      BiosProtectionState.unlockingSucceeded      : S.of(context)!.biosProtectionCardSubtitileUnlockingSucceeded,
    };

    return NotificationItem(
      S.of(context)!.biosProtectionCardTitle,
      biosProtectionStateSubtitles[_biosProtectionState].toString(),
      Icons.memory_rounded,
      state: mapStates[_biosProtectionState]!,
      onPress: () async {
        switch (_biosProtectionState) {
          case BiosProtectionState.unlockingSetupPwdFailed:
          case BiosProtectionState.missingSetupPwd:
            /* Request Setup Password */
            _showRequestPwdModal(
              S.of(context)!.biosProtectionAlertRequiredSetupPwdTitle,
              S.of(context)!.biosProtectionAlertRequiredSetupPwdP1,
              S.of(context)!.biosProtectionAlertRequiredSetupPwdHint,
            );
            break;
          case BiosProtectionState.missingSysPwd:
          case BiosProtectionState.unlockingSysPwdFailed:
            /* Request System Password */
            _showRequestPwdModal(
              S.of(context)!.biosProtectionAlertRequiredSysPwdTitle,
              S.of(context)!.biosProtectionAlertRequiredSysPwdP1,
              S.of(context)!.biosProtectionAlertRequiredSysPwdHint,
            );
            break;
          case BiosProtectionState.enforcedOwnerPwd:
            /* Cannot run without Setup/System password */
            _showEnforcedOwnerPwdModal();
            break;
          default:
            return;
        }
      },
    );
  }
}
