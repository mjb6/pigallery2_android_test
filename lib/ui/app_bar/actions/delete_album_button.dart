import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_snackbar.dart';
import 'package:provider/provider.dart';

class DeleteAlbumButton extends StatelessWidget {
  const DeleteAlbumButton({super.key});

  void onPressed(BuildContext context) async {
    AlbumRepository albumRepository = context.read();
    GalleryModel galleryModel = context.read<TabModelsProvider>().model!;
    Directory album = galleryModel.currentState.baseDirectory!;

    bool? delete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete album'),
        content: Text("Do you really want to delete album '${album.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (delete == null || !delete) return;

    try {
      await albumRepository.deleteAlbum(album.id);
      if (!context.mounted) return;
      onBackInvoked(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album deleted')));
      galleryModel.fetch();
    } catch (e) {
      if (!context.mounted) return;
      showErrorSnackbar('Failed to delete album: $e', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onPressed(context),
      icon: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
