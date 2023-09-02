import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  const MenuItem(this.title, this.icon, {super.key, this.description = "", this.autoHide = true, this.paddingH = 0, this.paddingV = 0, this.onPress, this.isSelected = false});

  final String title;
  final String description;
  final bool autoHide;
  final double paddingH;
  final double paddingV;
  final IconData icon;
  final bool isSelected;
  final onPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
      child: InkWell(
        onTap: onPress,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Icon(
                icon,
                color: !isSelected ? Theme.of(context).iconTheme.color : Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: !isSelected ? 
                      Theme.of(context).textTheme.titleMedium : 
                      Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 5,),
                  Text(description, textAlign: TextAlign.justify,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
