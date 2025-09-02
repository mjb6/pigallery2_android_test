import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:provider/provider.dart';

class FlattenDirButton extends StatelessWidget {
  const FlattenDirButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HomeModel model = context.read<HomeModel>();
        model.flattenDir();
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            pageBuilder: ((context, _, _) => HomeView(model.stackPosition)),
          ),
        );
      },
      icon: Icon(
        Ionicons.git_branch_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
