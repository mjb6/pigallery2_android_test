import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/views/website_view.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/horizontal_carousel_wrapper.dart';
import 'package:pigallery2_android/ui/shared/widgets/keep_alive_widget.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:provider/provider.dart';

class HomeViewFront extends StatelessWidget {
  const HomeViewFront({super.key});

  List<Widget> _getTabs(BuildContext context) {
    return [
      KeepAliveWidget(child: HomeViewGalleryPage(position: 0)),
      KeepAliveWidget(child: HomeViewGalleryPage(position: 1)),
      KeepAliveWidget(child: WebsiteView()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = _getTabs(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        HorizontalCarouselWrapper(
          initialIndex: 0,
          itemCount: tabs.length,
          builder: (context, index) => tabs[index],
          onPageScroll: context.read<TabStateModel>().setTabScroll,
        ),
      ],
    );
  }
}

class HomeViewGalleryPage extends StatelessWidget {
  final int position;

  const HomeViewGalleryPage({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKeys[position]!,
      onGenerateRoute: (routeSettings) {
        int stackPosition =
            routeSettings.arguments as int? ??
            context.read<GalleryModelProvider>().getModelByTab(position).stackPosition;
        return PageRouteBuilder(
          transitionDuration: fadeTransitionDuration,
          reverseTransitionDuration: fadeTransitionReverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          pageBuilder: (context, _, _) {
            return Provider.value(
              value: TabEntry.fromPosition(position),
              builder: (context, child) => ChangeNotifierProvider<GalleryModel>.value(
                value: context.read<GalleryModelProvider>().getModelByTab(position),
                child: GalleryView(stackPosition),
              ),
            );
          },
        );
      },
    );
  }
}
