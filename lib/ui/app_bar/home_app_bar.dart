import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/app_bar/actions/flatten_dir_button.dart';
import 'package:pigallery2_android/ui/app_bar/actions/server_settings_action.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/app_bar/search/gallery_search_delegate.dart';
import 'package:pigallery2_android/ui/app_bar/actions/animated_backdrop_toggle_button.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_selector.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

enum AppBarAction { back, search, flatten, backdrop, settings, sort }

class AppBarState {
  final String title;
  final Set<AppBarAction> actions;

  AppBarState({required this.title, required this.actions});
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  Set<AppBarAction> buildActions(BuildContext context) {
    Set<AppBarAction> actions = {AppBarAction.sort};

    bool canGoBack = context.select<AppBarModel, bool>((it) => it.canGoBack);
    if (canGoBack) {
      actions.add(AppBarAction.back);
    }
    final tab = context.select<TabStateModel, TabEntry>((it) => it.currentTab);

    if (!canGoBack && tab != TabEntry.website) {
      actions.add(AppBarAction.backdrop);
    }
    actions.add(AppBarAction.settings);

    bool isAlbumView = context.select<GalleryModelSelector, bool>((it) => it.model?.isAlbumView == true);
    if (isAlbumView) return actions;
    
    bool isServerConfigured = context.select<ServerRepository, bool>((it) => it.serverUrl != null);
    bool isSearching = context.select<GalleryModelSelector, bool>((it) => it.model?.currentState.isSearching == true);
    bool areDirectoriesDisplayed = context.select<AppBarModel, bool>((it) => it.areDirectoriesDisplayed);
    if (isServerConfigured && !isSearching && tab != TabEntry.website) {
      actions.add(AppBarAction.search);
      if (areDirectoriesDisplayed) {
        actions.add(AppBarAction.flatten);
      }
    }
    return actions;
  }

  /// not using AppBar since it doesn't properly keep top padding when status bar is hidden
  Widget buildAppBarContainer(BuildContext context, {required Widget child}) {
    ThemeData theme = Theme.of(context);
    final statusBarHeight = SystemUi.getPadding().top;
    return Container(
      padding: EdgeInsets.fromLTRB(6, statusBarHeight, 6, statusBarHeight == 0 ? 0 : 6),
      color: theme.appBarTheme.backgroundColor,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppBarState state = AppBarState(
      title: context.select<AppBarModel, String>((it) => it.title),
      actions: buildActions(context),
    );
    return buildAppBarContainer(
      context,
      child: _HomeAppBarInner(
        state,
        key: ObjectKey(state),
      ),
    );
  }
}

class _HomeAppBarInner extends StatelessWidget {
  final AppBarState state;
  const _HomeAppBarInner(this.state, {super.key});

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];
    if (state.actions.contains(AppBarAction.search)) {
      actions.add(
        IconButton(
          onPressed: () async {
            GalleryModel model = context.read<GalleryModelSelector>().model!;
            model.startSearch();
            await showSearch(
              context: context,
              delegate: GallerySearchDelegate(context.read<GalleryModelSelector>().model!.stackPosition),
            );

            /// transitionDuration of _SearchPageRoute is 300ms
            Future.delayed(Duration(milliseconds: 300)).then((it) {
              model.stopSearch();
            });
          },
          icon: const Icon(Icons.search),
        ),
      );
    }
    if (state.actions.contains(AppBarAction.settings)) {
      actions.add(IconButton(onPressed: () => showServerSettings(context), icon: const Icon(Icons.settings)));
    }
    if (state.actions.contains(AppBarAction.backdrop)) {
      actions.add(const AnimatedBackdropToggleButton());
    }
    if (state.actions.contains(AppBarAction.flatten)) {
      actions.add(const FlattenDirButton());
    }
    if (state.actions.contains(AppBarAction.sort)) {
      actions.add(const SortOptionWidget());
    }
    return actions;
  }

  Widget _buildNavigation(BuildContext context) {
    if (state.actions.contains(AppBarAction.back)) {
      return IconButton(
        onPressed: () {
          context.read<TabNavigatorModel>().goBack();
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          context.read<GalleryModelSelector>().model?.popStack();
        },
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildTitle(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Expanded(
      child: Text(
        state.title == "." ? "" : state.title,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  List<Widget> _buildLeading(BuildContext context) {
    return [
      _buildNavigation(context),
      SizedBox(width: 6),
      _buildTitle(context),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: theme.iconButtonTheme.style?.copyWith(padding: WidgetStateProperty.all(EdgeInsets.zero)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ..._buildLeading(context),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: _buildActions(context)),
        ],
      ),
    );
  }
}
