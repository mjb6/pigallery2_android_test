import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/app_bar/actions/server_settings_action.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/util/strings.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_grid_view.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_view.dart';
import 'package:pigallery2_android/ui/shared/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class GalleryView extends StatelessWidget {
  final int stackPosition;

  GalleryView(this.stackPosition) : super(key: ValueKey(stackPosition));

  void checkForError(BuildContext context, String? error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    GalleryModel model = Provider.of<GalleryModel>(context, listen: false);
    if (error != null) {
      SnackBar snackBar = SnackBar(
        action: error.contains(Strings.errorNoServerConfigured)
            ? SnackBarAction(
                label: "Add",
                onPressed: () => showServerSettings(context),
              )
            : model.stateOf(stackPosition).isSearching
            ? null
            : SnackBarAction(
                label: "Reload",
                onPressed: model.fetchItems,
              ),
        content: Text(error),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        duration: const Duration(days: 365),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        if (stackPosition == 0 &&
            context.read<TabEntry>() == TabEntry.home &&
            !context.select<GalleryModel, bool>((it) => it.searchOngoing))
          const TopPicksView(),
        Flexible(
          child: Selector<GalleryModel, List<Item>>(
            selector: (context, model) => model.stateOf(stackPosition).items,
            builder: (context, files, child) {
              return GalleryViewGridView(stackPosition, files);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GalleryModel, bool>(
      selector: (context, model) => model.stateOf(stackPosition).isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) return const LoadingIndicator();
        return Selector<GalleryModel, String?>(
          shouldRebuild: (String? previous, String? next) => true,
          selector: (context, model) => model.stateOf(stackPosition).error,
          builder: (BuildContext context, error, Widget? child) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                checkForError(context, error);
              });
            }
            return buildBody(context);
          },
        );
      },
    );
  }
}
