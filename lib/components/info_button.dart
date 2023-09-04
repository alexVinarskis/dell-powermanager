import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Widget _getCredits(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Made by ${Constants.authorName} in ', style: GoogleFonts.sourceCodePro().copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5))),
          TextSpan(text: '🇨🇭', style: GoogleFonts.notoColorEmoji()),
        ],
      ),
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
            child: const Text('Homepage'),
          ),
          PopupMenuItem<SampleItem>(
            value: SampleItem.itemBug,
            onTap: () {
              _launchURL(Constants.urlBugReport);
            },
            child: const Text('Report Bug'),
          ),
          PopupMenuItem<SampleItem>(
            value: SampleItem.itemCredits,
            enabled: false,
            child: _getCredits(context),
          ),
        ],
      ),
    );
  }
}
