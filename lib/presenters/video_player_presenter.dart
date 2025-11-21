import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/assets_video.dart';
import '../services/video_schedule_service.dart';

abstract class VideoPlayerView {
  void showError(String message);
  void showSuccess(String message);
  void updateVideo(ChewieController chewieController);
  void updatePlaybackInfo(int currentIndex, int totalVideos, String currentVideo);
  BuildContext get context;
}

class VideoPlayerPresenter {
  VideoPlayerView? _view;
  final VideoScheduleService _scheduleService = VideoScheduleService();

  ChewieController? _chewieController;
  List<VideoPlayerController> _allControllers = [];
  int _currentIndex = 0;
  bool _isInitialized = false;

  void attachView(VideoPlayerView view) => _view = view;

  Future<void> init() async {
    try {
      // Load schedule first
      await _scheduleService.loadSchedule();

      // Check if schedule is available
      final schedule = _scheduleService.getCurrentSchedule();
      if (schedule == null) {
        _view?.showError("কোনো সিডিউল পাওয়া যায়নি। JSON ফাইল চেক করুন।");
        return;
      }

      await _loadAndStartPlaylist();
      _isInitialized = true;
      _view?.showSuccess("ভিডিও প্লেয়ার প্রস্তুত হয়েছে");
    } catch (e) {
      _view?.showError("ইনিশিয়ালাইজ করতে সমস্যা: $e");
    }
  }

  Future<void> _loadAndStartPlaylist() async {
    final schedule = _scheduleService.getCurrentSchedule();
    if (schedule == null) {
      _view?.showError("কোনো সিডিউল পাওয়া যায়নি");
      return;
    }

    // Get all video paths from schedule
    final videoPaths = _scheduleService.getAllVideoPaths();

    if (videoPaths.isEmpty) {
      _view?.showError("প্লেলিস্টে কোনো ভিডিও নেই");
      return;
    }

    _view?.showSuccess("${videoPaths.length}টি ভিডিও লোড করা হচ্ছে...");
    await _preloadAllVideos(videoPaths);

    if (_allControllers.isNotEmpty) {
      _startPlaybackLoop();
      _view?.showSuccess("ভিডিও প্লেব্যাক শুরু হয়েছে");
    }
  }

  Future<void> _preloadAllVideos(List<String> assetPaths) async {
    _allControllers.clear();
    _currentIndex = 0;

    for (var assetPath in assetPaths) {
      try {
        // Pass context to AssetVideoLoader
        final localPath = await AssetVideoLoader.getLocalPath(_view!.context, assetPath);
        final controller = VideoPlayerController.file(File(localPath));
        await controller.initialize();
        _allControllers.add(controller);
        print('ভিডিও প্রিলোড করা হয়েছে: $assetPath');
      } catch (e) {
        debugPrint("ভিডিও স্কিপ করা হয়েছে: $assetPath → $e");
        _view?.showError("ভিডিও লোড করতে সমস্যা: ${assetPath.split('/').last}");
      }
    }

    _allControllers.removeWhere((c) => !c.value.isInitialized);

    if (_allControllers.isEmpty) {
      _view?.showError("চালানোর মতো কোনো ভিডিও নেই");
    } else {
      _view?.showSuccess("${_allControllers.length}টি ভিডিও প্রস্তুত হয়েছে");
    }
  }

  void _startPlaybackLoop() {
    if (_allControllers.isEmpty) {
      _view?.showError("চালানোর মতো কোনো ভিডিও নেই");
      return;
    }

    _playCurrent();
    _allControllers[_currentIndex].addListener(_videoListener);
    _updatePlaybackInfo();
  }

  void _videoListener() {
    final controller = _allControllers[_currentIndex];
    if (controller.value.isCompleted) {
      controller.removeListener(_videoListener);
      _nextVideo();
    }
  }

  void _playCurrent() {
    if (_allControllers.isEmpty || _currentIndex >= _allControllers.length) return;

    final vpController = _allControllers[_currentIndex];

    _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: vpController,
      autoPlay: true,
      looping: false,
      showControls: false,
      allowFullScreen: false,
      materialProgressColors:  ChewieProgressColors(
        playedColor: Colors.transparent,
        handleColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        bufferedColor: Colors.transparent,
      ),
      placeholder: Container(color: Colors.black),
    );

    _view?.updateVideo(_chewieController!);
    _updatePlaybackInfo();
  }

  void _nextVideo() {
    if (_allControllers.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % _allControllers.length;
    _playCurrent();
    _allControllers[_currentIndex].addListener(_videoListener);
  }

  void _updatePlaybackInfo() {
    if (_allControllers.isEmpty) return;

    final currentVideoPath = _scheduleService.getAllVideoPaths()[_currentIndex];
    final currentVideoName = currentVideoPath.split('/').last;

    _view?.updatePlaybackInfo(
      _currentIndex + 1,
      _allControllers.length,
      currentVideoName,
    );
  }

  // Public control methods
  void play() {
    _chewieController?.play();
  }

  void pause() {
    _chewieController?.pause();
  }

  void skipToNext() {
    if (_allControllers.isEmpty) return;

    _allControllers[_currentIndex].removeListener(_videoListener);
    _nextVideo();
  }

  void restartPlaylist() {
    if (_allControllers.isEmpty) return;

    _allControllers[_currentIndex].removeListener(_videoListener);
    _currentIndex = 0;
    _playCurrent();
    _allControllers[_currentIndex].addListener(_videoListener);
  }

  Map<String, dynamic> getPlaybackInfo() {
    return {
      'currentIndex': _currentIndex,
      'totalVideos': _allControllers.length,
      'isPlaying': _chewieController?.isPlaying ?? false,
      'isInitialized': _isInitialized,
    };
  }

  Map<String, dynamic> getScheduleInfo() {
    return _scheduleService.getScheduleInfo();
  }

  Future<void> refreshSchedule() async {
    await _scheduleService.forceUpdateSchedule();
    await _loadAndStartPlaylist();
  }

  void dispose() {
    _chewieController?.dispose();
    for (var c in _allControllers) {
      c.removeListener(_videoListener);
      c.dispose();
    }
    _allControllers.clear();
    _scheduleService.dispose();
  }
}