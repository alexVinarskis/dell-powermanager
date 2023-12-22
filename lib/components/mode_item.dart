import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'package:touch_interceptor/touch_interceptor.dart';

enum OptionState {
  unknown,
  selectSucceeded,
  selectFailed,
  selecting,
  deselected,
}

class ModeItem extends StatefulWidget {
  const ModeItem(this.title, {super.key, this.description = "", this.paddingH = 0, this.paddingV = 0, this.onPress, this.isSelected = false, this.isSupported = true, this.backgroundColor = Colors.transparent, this.isLoading = false, this.bottomItem, this.isDataMissing = false});

  final String title;
  final String description;
  final double paddingH;
  final double paddingV;
  final bool isSelected;
  final bool isSupported;
  final bool isLoading;
  final bool isDataMissing;
  final Color backgroundColor;
  final Widget? bottomItem;
  final onPress;

  @override
  State<ModeItem> createState() => _ModeItemState();
}

class _ModeItemState extends State<ModeItem> {
  var state = 0;
  bool isHovering = false;

  Widget _getProgressBar(var state, BuildContext context) {
    switch (state) {
      case OptionState.selectSucceeded:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, value: 1,);
      case OptionState.selecting:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent);
      default:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.transparent,);
    }
  }

  Widget _getCard(BuildContext context, {bool showUnsupported = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Text(
            widget.title + (showUnsupported? " (${S.of(context)!.cctkModeTitleUnsupported})" : ""),
            style: !widget.isSelected ? 
              Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700) : 
              Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 5,),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Text(widget.description,
            textAlign: TextAlign.justify,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
        widget.bottomItem != null ?
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: widget.bottomItem,
          )
          :
          const SizedBox(height: 20,),
        _getProgressBar(widget.isSelected ? widget.isLoading ? OptionState.selecting : OptionState.selectSucceeded : OptionState.deselected, context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      color:  widget.isSelected ?  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5) : widget.backgroundColor,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: widget.paddingV, horizontal: widget.paddingH),
      child: widget.isDataMissing ?
        SkeletonAnimation(
          curve: Curves.easeInOutCirc,
          shimmerColor: Theme.of(context).colorScheme.secondaryContainer,
          gradientColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0),
          child: _getCard(context),
        )
        :
        widget.isSupported ?
          InkWell(
            onTap: widget.onPress,
            child: _getCard(context),
          )
          :
          Opacity(
            opacity: 0.4,
            child: InkWell(
              onTap: () {},
              onHover: (hovering) {
                setState(() {
                  isHovering = hovering;
                });
              },
              child: TouchInterceptor(
                child: _getCard(context, showUnsupported: isHovering),
              ),
            ),
          ),
    );
  }
}
