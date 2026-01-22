import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/shared/widgets/expanded_section.dart';

class TopPicksContainer extends StatelessWidget {
  final bool expand;
  final Widget? child;

  const TopPicksContainer({required this.expand, this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedSection(
      expand: expand,
      child: SizedBox(
        height: 132,
        child: child,
      ),
    );
  }
}
