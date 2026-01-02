import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;

  const RefreshWrapper({required this.scrollController, required this.child, super.key});

  @override
  State<RefreshWrapper> createState() => _RefreshWrapperState();
}

class _RefreshWrapperState extends State<RefreshWrapper> {
  late RefreshController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: _controller,
      enablePullDown: true,
      enablePullUp: false,
      header: WaterDropMaterialHeader(
        color: Theme.of(context).colorScheme.primary,
      ),
      scrollController: widget.scrollController,
      onRefresh: () async {
        await context.read<TabNavigatorModel>().refresh();
        _controller.refreshCompleted();
      },
      child: widget.child,
    );
  }
}
