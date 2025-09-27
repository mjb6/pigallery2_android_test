import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Holds a [VideoController] alongside its error events.
/// Required since error events are not buffered.
class VideoControllerItem extends ChangeNotifier {
  final VideoController controller;
  final List<String> _errorEvents = [];
  bool _firstFrameRendered = false;

  VideoControllerItem(this.controller) {
    controller.player.stream.error.listen((value) {
      _errorEvents.add(value);
    });
    controller.waitUntilFirstFrameRendered.then((_) {
      _firstFrameRendered = true;
      notifyListeners();
    });
  }

  Stream<String> errorStream() async* {
    for (String event in _errorEvents) {
      yield event;
    }
    yield* controller.player.stream.error;
  }

  Player get player => controller.player;

  bool get hasError => _errorEvents.isNotEmpty;

  bool get firstFrameRendered => _firstFrameRendered;
}
