import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 
import '../configs/constants.dart';

enum SampleItem { itemHomepage, itemBug, itemCredits }

class InfoButton extends StatelessWidget {
  const InfoButton({super.key, this.title = "", this.paddingH = 0, this.paddingV = 0});

  final String title;
  final double paddingH;
  final double paddingV;

  Widget getButtonTitle() {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          Expanded(child: Text(title, textAlign: TextAlign.center,),),
        ]
      ),
    );
  }

  _launchURL(String url) async {
    launchUrl(Uri.parse(url));
  }

  void _showAboutDialog({required BuildContext context}) {
    final List<Widget> aboutBoxChildren = <Widget>[
      const SizedBox(height: 24),
      SizedBox(
        width: 300,
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

  Widget _getTitleUrl(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        const Icon(Icons.link),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
      child: PopupMenuButton<SampleItem>(
        icon: getButtonTitle(),
        tooltip: "",
        elevation: 20,
        offset: const Offset(100, 0),
        position: PopupMenuPosition.over,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<SampleItem>>[
          PopupMenuItem<SampleItem>(
            value: SampleItem.itemHomepage,
            onTap: () {
              _launchURL(Constants.urlHomepage);
            },
            child: _getTitleUrl(S.of(context)!.infoButtonItemHomepage),
          ),
          PopupMenuItem<SampleItem>(
            value: SampleItem.itemBug,
            onTap: () {
              _launchURL(Constants.urlBugReport);
            },
            child: _getTitleUrl(S.of(context)!.infoButtonItemBug),
          ),
          PopupMenuItem<SampleItem>(
            value: SampleItem.itemCredits,
            onTap: () {
              _showAboutDialog(context: context);
            },
            child: Text(S.of(context)!.infoButtonItemAbout),
          ),
        ],
      ),
    );
  }
}
