import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_schedule_service.dart';

abstract class VideoPlayerView {
  void showError(String message);
  void showSuccess(String message);
  void updateVideo(Widget videoWidget);
  void updatePlaybackInfo(int currentIndex, int totalVideos, String currentVideo);
  BuildContext get context;
}

class VideoPlayerPresenter {
  VideoPlayerView? _view;
  final VideoScheduleService _scheduleService = VideoScheduleService();

  Widget? _currentVideoWidget;

  final List<StreamSubscription> _subscriptions = [];

  void attachView(VideoPlayerView view) {
    _view = view;
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    _subscriptions.add(_scheduleService.errorStream.listen((e) => _view?.showError(e)));
    _subscriptions.add(_scheduleService.successStream.listen((s) => _view?.showSuccess(s)));

    _subscriptions.add(_scheduleService.progressStream.listen((progress) {
      _view?.updatePlaybackInfo(
        progress['currentIndex'] ?? 1,
        progress['total'] ?? 1,
        progress['currentVideo'] ?? 'Loading...',
      );

      if (progress['forceRefresh'] == true) {
        final ctrl = _scheduleService.currentController;
        if (ctrl != null && ctrl.value.isInitialized) {
          _createVideoWidget(ctrl);
        }
      }
    }));
  }

  Future<void> init() async {
    try {
      _view?.showSuccess("Loading videos...");
      await _scheduleService.loadAllVideosFromAssets();
    } catch (e) {
      _view?.showError("Failed to start");
    }
  }

  void _createVideoWidget(VideoPlayerController controller) {
    _currentVideoWidget = VideoPlayer(controller);
    _view?.updateVideo(_currentVideoWidget!);
    print("Now showing: ${controller.dataSource.split('/').last}");
  }

  void play() => _scheduleService.play();
  void pause() => _scheduleService.pause();
  void skipToNext() => _scheduleService.next();
  void skipToPrevious() => _scheduleService.previous();
  void restartPlaylist() => _scheduleService.loadAllVideosFromAssets();

  Future<void> refreshSchedule() async {
    _view?.showSuccess("Reloading...");
    await _scheduleService.loadAllVideosFromAssets();
  }

  void dispose() {
    for (var s in _subscriptions) s.cancel();
    _subscriptions.clear();
    _scheduleService.dispose();
  }
}