import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_state.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_snackbar.dart';
import 'package:provider/provider.dart';

class SaveAlbumButton extends StatelessWidget {
  const SaveAlbumButton({super.key});

  void onPressed(BuildContext context) async {
    AlbumRepository albumRepository = context.read();
    GalleryModel albumModel = context.read<TabModelsProvider>().getModelByTab(TabEntry.albums.pos);
    SearchGalleryModelStateType stateType =
        context.read<TabModelsProvider>().model!.currentState.type as SearchGalleryModelStateType;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create album'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Album name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final query = stateType.query;
    try {
      await albumRepository.createAlbum(name, query);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album created')));
      albumModel.fetch();
    } catch (e) {
      if (!context.mounted) return;
      showErrorSnackbar('Failed to create album: $e', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onPressed(context),
      icon: Icon(
        Icons.save_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
