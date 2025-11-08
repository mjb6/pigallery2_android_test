import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/app_bar/actions/flatten_dir_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/app_bar/search/gallery_search_delegate.dart';
import 'package:pigallery2_android/ui/app_bar/views/website_view.dart';
import 'package:pigallery2_android/ui/app_bar/actions/animated_backdrop_toggle_button.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_selector.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback showServerSettings;

  const HomeAppBar(this.showServerSettings, {super.key});

  void showAdminPanel(BuildContext context, String serverUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WebsiteView(serverUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // animation that slides the page in from the right
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, int stackPosition) {
    List<Widget> actions = [];
    bool isServerConfigured = context.select<GalleryModelSelector, bool>((it) => it.model.isServerConfigured);
    bool isSearching = context.select<GalleryModelSelector, bool>((it) => it.model.stateOf(stackPosition).isSearching);
    bool areDirectoriesDisplayed = context.select<GalleryModelSelector, bool>(
      (it) => it.model.stateOf(stackPosition).directories.isNotEmpty,
    );
    if (isServerConfigured && !isSearching) {
      actions.add(
        IconButton(
          onPressed: () async {
            GalleryModel model = context.read<GalleryModelSelector>().model;
            model.startSearch();
            await showSearch(context: context, delegate: GallerySearchDelegate(stackPosition));
            /// transitionDuration of _SearchPageRoute is 300ms
            Future.delayed(Duration(milliseconds: 300)).then((it) {
              model.stopSearch();
            });
          },
          icon: const Icon(Icons.search),
        ),
      );
    }
    if (stackPosition == 0) {
      actions.add(IconButton(onPressed: showServerSettings, icon: const Icon(Icons.settings)));
    }
    if (stackPosition == 0 && isServerConfigured) {
      actions.add(
        IconButton(
          onPressed: () {
            String? url = context.read<ServerRepository>().serverUrl;
            url?.let((it) => showAdminPanel(context, it));
          },
          icon: const Icon(Icons.manage_accounts),
        ),
      );
    }
    if (stackPosition == 0) {
      actions.add(const AnimatedBackdropToggleButton());
    }
    if (isServerConfigured && !isSearching && areDirectoriesDisplayed) {
      actions.add(const FlattenDirButton());
    }
    actions.addAll([const SortOptionWidget()]);
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    int stackPosition = context.select<GalleryModelSelector, int>((it) => it.model.stackPosition);
    String? directoryName = context.select<GalleryModelSelector, String?>((it) => it.model.currentState.title);
    final statusBarHeight = SystemUi.getPadding().top;

    // not using AppBar since it doesn't properly keep top padding when status bar is hidden
    return Container(
      padding: EdgeInsets.fromLTRB(6, statusBarHeight, 6, statusBarHeight == 0 ? 0 : 6),
      color: theme.appBarTheme.backgroundColor,
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: theme.iconButtonTheme.style?.copyWith(padding: WidgetStateProperty.all(EdgeInsets.zero)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stackPosition > 0)
              IconButton(
                onPressed: () { 
                  context.read<GalleryModelSelector>().popRoute();
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  context.read<GalleryModelSelector>().model.popStack();
                },
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
              ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                directoryName == "." ? "" : directoryName ?? "",
                overflow: TextOverflow.fade,
                softWrap: false,
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: _buildActions(context, stackPosition)),
          ],
        ),
      ),
    );
  }
}
