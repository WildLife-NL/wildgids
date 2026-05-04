import 'package:flutter/material.dart';

class SplitRowContainer extends StatelessWidget {
  final Widget? leftWidget;
  final Widget? rightWidget;
  final double spacing;

  const SplitRowContainer({
    super.key,
    this.leftWidget,
    this.rightWidget,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leftWidget ?? const SizedBox(),
          SizedBox(width: spacing),
          rightWidget ?? const SizedBox(),
        ],
      ),
    );
  }
}
