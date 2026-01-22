import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'widgets/suggestions_overlay.dart';
import 'search_viewmodel.dart';

class SearchPage extends StatefulWidget {
  final int baseStackPosition;
  final Directory? baseDirectory;

  const SearchPage({super.key, required this.baseStackPosition, this.baseDirectory});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  void _applyAutoCompleteItem(SearchViewModel vm, AutoCompleteItem item) {
    final q = vm.query;
    final trimmedLeft = q.trimLeft();
    final leadingSpaces = q.length - trimmedLeft.length;
    final tokens = trimmedLeft.isEmpty ? <String>[] : trimmedLeft.split(RegExp(r'\s+'));

    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    String? keyword;
    switch (item.type) {
      case SearchQueryTypes.directory:
        keyword = keywords.directory;
        break;
      case SearchQueryTypes.fileName:
        keyword = keywords.fileName;
        break;
      case SearchQueryTypes.caption:
        keyword = keywords.caption;
        break;
      case SearchQueryTypes.person:
        keyword = keywords.person;
        break;
      case SearchQueryTypes.position:
        keyword = keywords.position;
        break;
      case SearchQueryTypes.keyword:
        keyword = keywords.keyword;
        break;
      default:
        keyword = null;
    }

    String wrapped = item.text.contains(' ') ? '"${item.text.replaceAll('"', '\\"')}"' : item.text;
    final replacementToken = keyword != null ? '$keyword:$wrapped' : wrapped;

    if (tokens.isEmpty) {
      vm.query = '${' ' * leadingSpaces}$replacementToken ';
      return;
    }

    final last = tokens.last;
    final index = trimmedLeft.lastIndexOf(last);
    final prefix = trimmedLeft.substring(0, index);
    vm.query = '${' ' * leadingSpaces}${prefix.isEmpty ? '' : prefix}$replacementToken ';
  }

  @override
  Widget build(BuildContext context) {
    int tabPosition = TabEntry.home.pos;
    final GalleryModel model = context.read<TabModelsProvider>().getModelByTab(TabEntry.home.pos);
    final stackPosition = context.select<TabModelsProvider, int>((it) => it.getModelByTab(tabPosition).stackPosition);
    final pos = stackPosition == widget.baseStackPosition + 1 ? stackPosition : widget.baseStackPosition;
    final SearchViewModel vm = context.read<TabModelsProvider>().getSearchModelByTab(tabPosition);

    return Stack(
      children: [
        Provider.value(
          value: TabEntry.home,
          builder: (context, child) => ChangeNotifierProvider<GalleryModel>.value(
            value: model,
            child: GalleryView(pos),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: ChangeNotifierProvider.value(
                value: vm,
                child: Consumer<SearchViewModel>(
                  builder: (context, _, _) {
                    if (!vm.showOverlay) return const SizedBox.shrink();
                    return SuggestionsOverlay(
                      query: vm.query,
                      keywords: SearchQueryParser().keywords,
                      onInsertToken: (token) {
                        final trimmedLeft = vm.query.trimLeft();
                        final leadingSpaces = vm.query.length - trimmedLeft.length;
                        final tokens = trimmedLeft.isEmpty ? <String>[] : trimmedLeft.split(RegExp(r'\s+'));
                        if (tokens.isEmpty) {
                          vm.query = '${' ' * leadingSpaces}$token';
                          return;
                        }
                        final last = tokens.last;
                        final index = trimmedLeft.lastIndexOf(last);
                        final prefix = trimmedLeft.substring(0, index);
                        vm.query = '${' ' * leadingSpaces}$prefix$token';
                      },
                      onApplyItem: (item, ctx) {
                        _applyAutoCompleteItem(vm, item);
                        FocusScope.of(context).requestFocus(vm.focusNode);
                      },
                      onReplaceQuery: (newQ) {
                        vm.query = newQ;
                        vm.showOverlay = true;
                      },
                      onEditToken: (token) {
                        vm.query = token;
                        FocusScope.of(context).requestFocus(vm.focusNode);
                        vm.showOverlay = true;
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
