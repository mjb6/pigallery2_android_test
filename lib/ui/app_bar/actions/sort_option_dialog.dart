import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_provider.dart';
import 'package:pigallery2_android/ui/shared/widgets/selectable_card.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:provider/provider.dart';

class SortOptionDialog extends StatelessWidget {
  const SortOptionDialog({super.key});

  List<Widget> _buildSortTypeItems(BuildContext context, SortType selectedType) {
    List<Widget> listItems = [];
    for (SortType type in SortType.values) {
      listItems.add(
        SizedBox(
          height: kMinInteractiveDimension,
          child: SelectableCard(
            isSelected: type == selectedType,
            onSelected: () => context.read<GalleryModelProvider>().model!.setSortType(type),
            title: Text(type.getDisplayName()),
          ),
        ),
      );
    }
    return listItems;
  }

  List<Widget> _buildSortOrderItems(BuildContext context, SortOrder selectedSortOrder) {
    List<Widget> listItems = [];
    for (SortOrder order in SortOrder.values) {
      listItems.add(
        SizedBox(
          height: kMinInteractiveDimension,
          child: SelectableCard(
            isSelected: order == selectedSortOrder,
            onSelected: () => context.read<GalleryModelProvider>().model!.setSortOrder(order),
            title: Text(order.getDisplayName()),
          ),
        ),
      );
    }
    return listItems;
  }

  Widget _buildCheckBox(BuildContext context, bool onlyThisFolder) {
    return SizedBox(
      child: Container(
        margin: EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.circular(10),
            ),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () {
              context.read<GalleryModelProvider>().model!.setSortOnlyThisFolder(!onlyThisFolder);
            },
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 6),
              title: Text("Only this folder"),
              trailing: IgnorePointer(
                child: Checkbox(
                  value: onlyThisFolder,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._buildSortTypeItems(context, context.select<GalleryModelProvider, SortType>((it) => it.model!.sortOption.type)),
        const Divider(thickness: 3),
        ..._buildSortOrderItems(context, context.select<GalleryModelProvider, SortOrder>((it) => it.model!.sortOption.order)),
        _buildCheckBox(context, context.select<GalleryModelProvider, bool>((it) => it.model!.sortOption.onlyThisFolder)),
      ],
    );
  }
}
