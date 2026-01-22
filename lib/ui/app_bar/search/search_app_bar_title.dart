import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:provider/provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';

class SearchAppBarTitle extends StatelessWidget {
  const SearchAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TabModelsProvider>().searchModel!;
    final currentScroll = context.select<TabStateModel, double>((it) => it.currentScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (currentScroll == 0 && vm.showOverlay == true) {
        vm.focusNode.requestFocus();
      }
    });
    return Expanded(
      child: TextField(
        controller: vm.controller,
        focusNode: vm.focusNode,
        decoration: const InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
        ),
        onTap: () {
          vm.showOverlay = true;
        },
        onChanged: (v) => vm.query = v,
        onSubmitted: (v) {
          try {
            final dto = SearchQueryParser().parse(v);
            context.read<TabModelsProvider>().model!.search(dto);
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Invalid search query: ${e.toString()}')));
          }
          vm.showOverlay = false;
          vm.focusNode.unfocus();
        },
      ),
    );
  }
}
