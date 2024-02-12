import 'package:flutter/material.dart';
import '../configs/constants.dart';

enum NotificationState {
  hidden,
  present,
  loading,
  succeeded,
  failedLoading,
  failedNotification,
}

class NotificationItem extends StatefulWidget {
  const NotificationItem(
    this.title,
    this.description,
    this.icon,
    {
      super.key,
      this.paddingH = 20,
      this.paddingV = 10,
      this.onPress,
      this.backgroundColor = Colors.amber,
      this.backgroundOpacity = 0.4,
      this.state = NotificationState.hidden,
      this.iconFailedLoading = Icons.error_outline_rounded,
      this.iconFailedNotification = Icons.warning_amber_rounded,
      this.iconSucceeded = Icons.check_circle_outline_outlined,
    }
  );

  final IconData icon;
  final String title;
  final String description;
  final NotificationState state;
  final IconData iconSucceeded;
  final IconData iconFailedLoading;
  final IconData iconFailedNotification;
  final double paddingH;
  final double paddingV;
  final Color backgroundColor;
  final double backgroundOpacity;
  final onPress;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  Widget _getProgressBar(BuildContext context) {
    switch (widget.state) {
      case NotificationState.loading:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent);
      case NotificationState.failedLoading:
        return LinearProgressIndicator(backgroundColor: Colors.transparent, color: Theme.of(context).colorScheme.error, value: 1,);
      case NotificationState.succeeded:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.green, value: 1,);
      default:
        return const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.transparent,);
    }
  }

  Widget _getIcon(BuildContext context) {
    switch (widget.state) {
      case NotificationState.failedLoading:
        return Icon(widget.iconFailedLoading, color: Theme.of(context).colorScheme.error,);
      case NotificationState.failedNotification:
        return Icon(widget.iconFailedNotification);
      case NotificationState.succeeded:
        return Icon(widget.iconSucceeded, color: Colors.green,);
      default:
        return Icon(widget.icon);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: Constants.animationMs),
      child:  widget.state != NotificationState.hidden ? Card(
        key: Key("${widget.title}_notificationAvailableTrue"),
        clipBehavior: Clip.antiAlias,
        color: (widget.state == NotificationState.failedNotification ? Colors.red : widget.backgroundColor).withOpacity(widget.backgroundOpacity),
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: widget.paddingV, horizontal: widget.paddingH),
        child: InkWell(
          onTap: widget.onPress,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: _getIcon(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5,),
                        Text(widget.description, textAlign: TextAlign.justify,),
                      ],
                    ),
                  ),
                ],
              ),
              Align(alignment: Alignment.bottomCenter, child: _getProgressBar(context),),
            ],
          ),
        ),
      ) : SizedBox(
        key: Key("${widget.title}_notificationAvailableFalse"),
      ),
    );
  }
}
