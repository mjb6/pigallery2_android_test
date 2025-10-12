import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';

enum StorageKey<T> {
  useMaterial3<bool>(true),
  showTopPicks<bool>(true),
  topPicksDaysLength<int>(1),
  sortOption<SortOption>(SortOption.name),
  sortAscending<bool>(true),
  showDirectoryItemCount<bool>(false),
  gridRoundedCorners<int>(6),
  gridSpacing<int>(6),
  gridAspectRatio<double>(1),
  gridCrossAxisCountPortrait<int>(4),
  gridCrossAxisCountLandscape<int>(6),
  allowBadCertificates<bool>(false),
  showVideoSeekPreview<bool>(false),
  mediaBackgroundMode<MediaBackgroundMode>(MediaBackgroundMode.ambient),
  mediaBackgroundBlur<int>(45),
  serverSettings<ServerSettings>(
    ServerSettings(
      servers: [],
      defaultApiSettings: ApiSettings(thumbnailPath: "/320", videoPath: ""),
      selectedServer: "",
    ),
  );

  String get key => name;
  final T defaultValue;

  const StorageKey(this.defaultValue);
}
