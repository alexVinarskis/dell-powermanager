import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

final Map<DependenciesState, String> dependenciesStateTitles = {
  DependenciesState.hidden                : "",
  DependenciesState.awaiting              : "Tap for more info and install options",
  DependenciesState.downloading           : "Please wait... Downloading...",
  DependenciesState.installing            : "Please wait... Installing...",
  DependenciesState.downloadFailed        : "Download Failed :<",
  DependenciesState.installationFailed    : "Installation Failed :<",
  DependenciesState.installationSucceeded : "Installation Succeeded",
};

class MenuDependencies extends StatefulWidget {
  const MenuDependencies({super.key, this.paddingH = 0, this.paddingV = 0, this.backgroundColor = Colors.transparent});

  final double paddingH;
  final double paddingV;
  final Color backgroundColor;

  @override
  State<MenuDependencies> createState() => MenuDependenciesState();
}

class MenuDependenciesState extends State<MenuDependencies> {
  // assume all dependencies are installed by default
  DependenciesState _dependenciesState = DependenciesState.hidden;

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

  Widget _getProgressBar(var state, BuildContext context) {
    switch (state) {
      case DependenciesState.installing:
      case DependenciesState.downloading:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent);
      case DependenciesState.installationFailed:
      case DependenciesState.downloadFailed:
        return LinearProgressIndicator(backgroundColor: Colors.transparent, color: Theme.of(context).colorScheme.error, value: 1,);
      case DependenciesState.installationSucceeded:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.green, value: 1,);
      default:
        return  const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.transparent,);
    }
  }

  Widget _getIcon(var state, BuildContext context) {
    switch (state) {
      case DependenciesState.installationFailed:
      case DependenciesState.downloadFailed:
        return Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error,);
      case DependenciesState.installationSucceeded:
        return const Icon(Icons.check_circle_outline_outlined, color: Colors.green,);
      default:
        return const Icon(Icons.warning_amber_rounded);
    }
  }

  Future<void> _showDownloadModal() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Missing Dependencies'),
          content: RichText(
            text: TextSpan(
              children: [
                TextSpan(text:
                  'This app requires ',
                  style: Theme.of(context).textTheme.bodyMedium
                ),
                TextSpan(text: '"Dell Command | Configure"', style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!)),
                TextSpan(text:
                  ' CLI\n'
                  'and its dependencies to operate. Press the button below\n'
                  'to automatically install the following packages:\n\n',
                  style: Theme.of(context).textTheme.bodyMedium
                ),
                TextSpan(text: Platform.isLinux ? Constants.packagesLinux.join('\n') : Constants.packagesWindows.join('\n'), style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!)),
                TextSpan(text:
                  '\n',
                  style: Theme.of(context).textTheme.bodyMedium
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
              label: const Text('Download and install'),
              onPressed: () {
                _getDependencies();
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: Constants.animationMs),
      child:  _dependenciesState != DependenciesState.hidden ? Card(
        key: const Key("depsMissingTrue"),
        clipBehavior: Clip.antiAlias,
        color: Colors.amber.withOpacity(0.4),
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: widget.paddingV, horizontal: widget.paddingH),
        child: InkWell(
          onTap: () {
            if (_dependenciesState == DependenciesState.installing || _dependenciesState == DependenciesState.downloading) {
              return;
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
                    child: _getIcon(_dependenciesState, context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missing Dependencies',
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5,),
                        Text(dependenciesStateTitles[_dependenciesState].toString(), textAlign: TextAlign.justify,),
                      ],
                    ),
                  ),
                ],
              ),
              Align(alignment: Alignment.bottomCenter, child: _getProgressBar(_dependenciesState, context),),
            ],
          ),
        ),
      ) : const SizedBox(
        key: Key("depsMissingFalse"),
      ),
    );
  }
}
