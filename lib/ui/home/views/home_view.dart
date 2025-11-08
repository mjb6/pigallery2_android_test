import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_selector.dart';
import 'package:pigallery2_android/ui/home/views/home_view_front.dart';
import 'package:pigallery2_android/ui/settings/views/settings_bottom_sheet.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/app_bar/views/back_layer.dart';
import 'package:pigallery2_android/ui/app_bar/home_app_bar.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void showServerSettings(BuildContext context) {
    showModalBottomSheet<int>(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      context: context,
      builder: (context) => SettingsBottomSheet(),
    ).whenComplete(() {
      if (!context.mounted) return;
      context.read<GalleryModelSelector>().model.fetchItems();
      Provider.of<TopPicksModel>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // BackdropScaffold does not enable predictive back gestures.
    // With it enabled, touch inputs are not registered for ~0.5s after the animation is finished.
    return PopScope(
      canPop: context.read<GalleryModelSelector>().model.stackPosition == 0,
      onPopInvokedWithResult: ((bool didPop, _) {
        context.read<GalleryModelSelector>().popRoute();
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        context.read<GalleryModelSelector>().model.popStack();
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
          child: HomeAppBar(() => showServerSettings(context)),
        ),
      ),
    );
  }
}
