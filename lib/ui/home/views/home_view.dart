import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_selector.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/views/home_view_front.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/app_bar/views/back_layer.dart';
import 'package:pigallery2_android/ui/app_bar/home_app_bar.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: ((bool didPop, _) {
        context.read<TabNavigatorModel>().goBack();
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        context.read<GalleryModelSelector>().model?.popStack();
      }),
      child: BackdropScaffold(
        primary: false,
        frontLayerBorderRadius: BorderRadius.zero,
        keepFrontLayerActive: true,
        stickyFrontLayer: true,
        frontLayer: HomeViewFront(),
        backLayer: BackLayer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(toolbarHeight + SystemUi.getPadding().top),
          child: HomeAppBar(),
        ),
      ),
    );
  }
}
