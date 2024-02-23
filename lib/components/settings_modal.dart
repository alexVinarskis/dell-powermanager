import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 
import '../classes/bios_protection_manager.dart';
import '../classes/ota_manager.dart';
import '../classes/sudoers_manager.dart';
import '../configs/constants.dart';


class SettingTile extends StatefulWidget {
  const SettingTile({super.key, required this.title, this.subtitle, this.subtitleAlt, this.icon, this.onPressed});

  final String title;
  final String? subtitle;
  final String? subtitleAlt;
  final IconData? icon;
  final Function? onPressed;

  @override
  State<SettingTile> createState() => SettingTileState();
}

class SettingTileState extends State<SettingTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))
        ),
        title: Text(widget.title),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        trailing: widget.icon == null ? null : Icon(widget.icon),
        subtitle: widget.subtitle == null ? null : !_pressed || widget.subtitleAlt == null ? Text(widget.subtitle!) : Text(widget.subtitleAlt!),
        onTap: widget.onPressed == null ? null : () {
          widget.onPressed!();
          setState(() {
            _pressed = true;
          });
          Timer(const Duration(seconds: 1), () {
            if (!mounted) {
              return;
            }
            setState(() {
              _pressed = false;
            });
          });
        },
      ),
    );
  }
}

class SettingTileToggle extends StatefulWidget {
  const SettingTileToggle({
    super.key,
    required this.title,
    this.subtitleEnabled,
    this.subtitleDisabled,
    this.subtitleEnabledAlt,
    this.subtitleDisabledAlt,
    required this.getPref,
    required this.setPref,
  });

  final String title;
  final String? subtitleEnabled;
  final String? subtitleDisabled;
  final String? subtitleEnabledAlt;
  final String? subtitleDisabledAlt;
  final Function getPref;
  final Function setPref;

  @override
  State<SettingTileToggle> createState() => SettingTileToggleState();
}

class SettingTileToggleState extends State<SettingTileToggle> {
  bool? _enabled;
  bool _enablePressed = false;
  bool _disablePressed = false;

  _fetchPref() async {
    bool enabled = await widget.getPref();
    if (mounted) {
      setState(() {
        _enabled = enabled;
      });
    }
  }

  _setPref(bool value) async {
    setState(() {
      _enabled = value;
    });
    if (value) {
      _disablePressed = false;
      _enablePressed = true;
      Timer(const Duration(seconds: 1), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _enablePressed = false;
        });
      });
    } else {
      _enablePressed = false;
      _disablePressed = true;
      Timer(const Duration(seconds: 1), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _disablePressed = false;
        });
      });
    }
    await widget.setPref(value);
  }

  String _getSubtitle() {
    if (_enabled ?? false) {
      return _enablePressed ? widget.subtitleEnabledAlt ?? widget.subtitleEnabled ?? '' : widget.subtitleEnabled ?? '';
    }
    return _disablePressed ? widget.subtitleDisabledAlt ?? widget.subtitleDisabled ?? '' : widget.subtitleDisabled ?? widget.subtitleEnabled ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null) {
      _fetchPref();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))
        ),
        title: Text(widget.title),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        trailing: Switch(
          value: _enabled ?? false,
          onChanged: (bool value) => _setPref(value),
        ),
        subtitle: Text(_getSubtitle()),
        onTap: () => _setPref(!(_enabled ?? false)),
      ),
    );
  }
}

class SettingsModal {

  static void _launchURL(String url) async {
    launchUrl(Uri.parse(url));
  }

  static void _showAboutDialog({required BuildContext context}) {
    final List<Widget> aboutBoxChildren = <Widget>[
      const SizedBox(height: 24),
      SizedBox(
        width: 450,
        child: Text(S.of(context)!.appDescription, textAlign: TextAlign.justify,),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Text('Made by ${Constants.authorName} in ', style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5))),
        SvgPicture.asset('assets/images/ch.svg', height: Theme.of(context).textTheme.bodyMedium!.fontSize,)
      ],),
    ];

    Future.delayed(
      const Duration(seconds: 0), () => showAboutDialog(
        context: context,
        applicationIcon: SvgPicture.asset('assets/images/icon.svg', height: 95,),
        applicationName: Constants.applicationName,
        applicationVersion: Constants.applicationVersion,
        applicationLegalese: Constants.applicationLegalese,
        children: aboutBoxChildren,
      ),
    );
  }

  static Widget _settingsBadge({required String title, required Function onPressed, Widget? icon}) {
    return FilledButton.tonal(
      onPressed: () => onPressed(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: icon ?? const SizedBox(),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(title, textAlign: TextAlign.center,),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showModal(BuildContext context, {double width = 450, double height = 0, double paddingH = 0, double paddingV = 0}) {    
    Key settingIntanceKey = UniqueKey();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context)!.settingsAlertTitle),
          content: SizedBox(
            width: 450,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  key: settingIntanceKey,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 15,),
                    Row(
                      children: [
                        Expanded(
                          child: _settingsBadge(
                            title: S.of(context)!.settingsAlertTileHomepage,
                            icon: const Icon(Icons.link),
                            onPressed:  () {
                              _launchURL(Constants.urlHomepage);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 15,),
                        Expanded(
                          child: _settingsBadge(
                            title: S.of(context)!.settingsAlertTileAbout,
                            onPressed:  () {
                              _showAboutDialog(context: context);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15,),
                    Row(
                      children: [
                        Expanded(
                          child: _settingsBadge(
                            title: S.of(context)!.settingsAlertTileBug,
                            icon: const Icon(Icons.link),
                            onPressed:  () {
                              _launchURL(Constants.urlBugReport);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 15,),
                        const Expanded(
                          child: SizedBox(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15,),
                    SettingTile(
                      title: S.of(context)!.settingsAlertResetBiosPwdTitle,
                      subtitle: S.of(context)!.settingsAlertResetBiosPwdSubTitleTodo,
                      subtitleAlt: S.of(context)!.settingsAlertResetBiosPwdSubTitleDone,
                      icon: Icons.delete_rounded,
                      onPressed: () => BiosProtectionManager.secureDeletePassword(),
                    ),
                    SettingTile(
                      title: S.of(context)!.settingsAlertResetSettingsTitle,
                      subtitle: S.of(context)!.settingsAlertResetSettingsSubTitleTodo,
                      subtitleAlt: S.of(context)!.settingsAlertResetSettingsSubTitleDone,
                      icon: Icons.delete_rounded,
                      onPressed: () async {
                        /* Erase saved preferences and cached variables */
                        SharedPreferences preferences = await SharedPreferences.getInstance();
                        await preferences.clear();
                        /* Undo sudoers patch, if applied, do NOT await */
                        if (Platform.isLinux) {
                          SudoersManager.unpatchSudoers();
                        }
                        /* Re-initialize settings modal, to reflect changes */
                        setState(() {
                          settingIntanceKey = UniqueKey();
                        });
                      },
                    ),
                    SettingTileToggle(
                      title: S.of(context)!.settingsAlertOtaEnabledTitle,
                      subtitleEnabled: S.of(context)!.settingsAlertOtaEnabledSubTitleEnabled,
                      subtitleEnabledAlt: S.of(context)!.settingsAlertOtaEnabledSubTitleEnabledAlt,
                      subtitleDisabled: S.of(context)!.settingsAlertOtaEnabledSubTitleDisabled,
                      getPref: OtaManager.isOtaCheckEnabled,
                      setPref: OtaManager.setOtaCheckEnabled,
                    ),
                  ],
                );
              }
            ),
          ),
        );
      },
    );
  }
}
