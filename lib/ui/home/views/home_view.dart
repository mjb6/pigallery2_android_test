import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pigallery2_android/ui/app_bar/actions/server_settings_action.dart';
import 'package:pigallery2_android/ui/app_bar/search/gallery_search_delegate.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/views/glass_nav_bar.dart';
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
        context.read<GalleryModelProvider>().model?.popStack();
      }),
      child: BackdropScaffold(
        primary: false,
        frontLayerBorderRadius: BorderRadius.zero,
        keepFrontLayerActive: true,
        stickyFrontLayer: true,
        frontLayer: Stack(
          fit: StackFit.expand,
          children: [
            HomeViewFront(),
            GlassNavBar(
              tabIcons: [
                Ionicons.image_outline,
                Ionicons.images_outline,
                Ionicons.globe_outline,
              ],
              actions: [Icons.settings],
              onTap: (i) async {
                if (i == 0) {
                  showServerSettings(context);
                } else if (i == 1) {
                  GalleryModel model = context.read<GalleryModelProvider>().model!;
                  model.startSearch();
                  await showSearch(context: context, delegate: GallerySearchDelegate(0));

                  /// transitionDuration of _SearchPageRoute is 300ms
                  Future.delayed(Duration(milliseconds: 300)).then((it) {
                    model.stopSearch();
                  });
                }
              },
            ),
          ],
        ),
        backLayer: Padding(
          padding: EdgeInsets.zero,
          child: BackLayer(),
        ),
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(toolbarHeight + SystemUi.getPadding().top),
          child: HomeAppBar(),
        ),
      ),
    );
  }
}
