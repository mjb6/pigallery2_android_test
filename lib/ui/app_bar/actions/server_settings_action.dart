import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/web_view_model.dart';
import 'package:pigallery2_android/ui/settings/views/settings_bottom_sheet.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:provider/provider.dart';

void showServerSettings(BuildContext context) {
  ServerRepository serverRepository = context.read();
  String? previousServerUrl = serverRepository.serverUrl;
  showModalBottomSheet<int>(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    isScrollControlled: true,
    context: context,
    builder: (context) => SettingsBottomSheet(),
    useRootNavigator: true
  ).whenComplete(() {
    if (!context.mounted) return;
    if (previousServerUrl == serverRepository.serverUrl) return;
    context.read<GalleryModelProvider>().refresh();
    context.read<WebViewModel>().updateUrl();
    Provider.of<TopPicksModel>(context, listen: false).refresh();
  });
}
