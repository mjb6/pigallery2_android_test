import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/app_bar/views/website_view.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_selector.dart';
import 'package:pigallery2_android/ui/settings/views/settings_bottom_sheet.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:provider/provider.dart';

class HomeViewFront extends StatefulWidget {
  const HomeViewFront({super.key});
  @override
  State<StatefulWidget> createState() => _HomeViewFrontState();
}

class _HomeViewFrontState extends State<HomeViewFront> with TickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    GalleryModelSelector selector = context.read();
    controller = TabController(length: 3, vsync: this);
    controller.addListener(() {
      selector.setPage(controller.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        TabBarView(
          controller: controller,
          // physics: const FasterPageViewScrollPhysics(),
          children: [
            HomeViewGalleryPage(position: 0),
            HomeViewGalleryPage(position: 1),
            WebsiteView(context.read<ServerRepository>().serverUrl!),
          ],
        ),
      ],
    );
  }
}

class HomeViewGalleryPage extends StatefulWidget {
  final int position;

  const HomeViewGalleryPage({super.key, required this.position});
  @override
  State<StatefulWidget> createState() => _HomeViewGalleryPageState();
}

class _HomeViewGalleryPageState extends State<HomeViewGalleryPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void showServerSettings(BuildContext context) {
    showModalBottomSheet<int>(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      context: context,
      builder: (context) => SettingsBottomSheet(),
    ).whenComplete(() {
      if (!context.mounted) return;
      context.read<GalleryModelSelector>().refetchItems();
      Provider.of<TopPicksModel>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Navigator(
      onGenerateRoute: (routeSettings) {
        int stackPosition =
            routeSettings.arguments as int? ??
            context.read<GalleryModelSelector>().getModelByPage(widget.position).stackPosition;
        return PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 100),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          pageBuilder: (context, _, _) {
            context.read<GalleryModelSelector>().registerPopRouteCallback(widget.position, () => Navigator.pop(context));
            return Provider.value(
              value: TabEntry.albums,
              builder: (context, child) => ChangeNotifierProvider<GalleryModel>.value(
                value: context.read<GalleryModelSelector>().getModelByPage(widget.position),
                child: GalleryView(stackPosition, () => showServerSettings(context)),
              ),
            );
          },
        );
      },
    );
  }
}
