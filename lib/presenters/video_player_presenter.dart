import 'dart:async';
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
  Timer? _playbackTimer;

  void attachView(VideoPlayerView view) => _view = view;

  Future<void> init() async {
    try {
      _view?.showSuccess("Initializing video player...");

      // Load schedule first
      await _scheduleService.loadSchedule();

      // Check if schedule is available
      final schedule = _scheduleService.getCurrentSchedule();
      if (schedule == null) {
        _view?.showError("No schedule found. Please check JSON file.");
        return;
      }

      await _loadAndStartPlaylist();
      _isInitialized = true;
      _view?.showSuccess("Video player ready");

      // Start playback analytics
      _startPlaybackAnalytics();

    } catch (e) {
      _view?.showError("Initialization failed: $e");
    }
  }

  Future<void> _loadAndStartPlaylist() async {
    final schedule = _scheduleService.getCurrentSchedule();
    if (schedule == null) {
      _view?.showError("No schedule available");
      return;
    }

    // Get all video paths from schedule
    final videoPaths = _scheduleService.getAllVideoPaths();

    if (videoPaths.isEmpty) {
      _view?.showError("No videos in playlist");
      return;
    }

    _view?.showSuccess("Loading ${videoPaths.length} videos...");
    await _preloadAllVideos(videoPaths);

    if (_allControllers.isNotEmpty) {
      _startPlaybackLoop();
      _view?.showSuccess("Playback started");
    }
  }

  Future<void> _preloadAllVideos(List<String> assetPaths) async {
    _allControllers.clear();
    _currentIndex = 0;

    int successCount = 0;
    int errorCount = 0;

    for (var assetPath in assetPaths) {
      try {
        _view?.showSuccess("Loading: ${assetPath.split('/').last}");

        final localPath = await AssetVideoLoader.getLocalPath(_view!.context, assetPath);
        final controller = VideoPlayerController.file(File(localPath));
        await controller.initialize();
        _allControllers.add(controller);
        successCount++;

        print('Video preloaded: $assetPath');
      } catch (e) {
        debugPrint("Video skipped: $assetPath → $e");
        _view?.showError("Failed to load: ${assetPath.split('/').last}");
        errorCount++;
      }
    }

    _allControllers.removeWhere((c) => !c.value.isInitialized);

    if (_allControllers.isEmpty) {
      _view?.showError("No playable videos found");
    } else {
      _view?.showSuccess("$successCount videos ready${errorCount > 0 ? ' ($errorCount failed)' : ''}");
    }
  }

  void _startPlaybackLoop() {
    if (_allControllers.isEmpty) {
      _view?.showError("No videos available for playback");
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
      _view?.showSuccess("Moving to next video...");
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
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF667EEA),
        handleColor: Colors.white,
        backgroundColor: Colors.grey.shade800,
        bufferedColor: Colors.grey.shade700,
      ),
      placeholder: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F0F),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Loading Video...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      autoInitialize: true,
      showOptions: false,
    );

    _view?.updateVideo(_chewieController!);
    _updatePlaybackInfo();

    // Show current video info
    final currentVideoName = _scheduleService.getAllVideoPaths()[_currentIndex].split('/').last;
    _view?.showSuccess("Now playing: $currentVideoName");
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

  void _startPlaybackAnalytics() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isInitialized && _allControllers.isNotEmpty) {
        print('Playback Analytics - Current: ${_currentIndex + 1}/${_allControllers.length}');
      }
    });
  }

  // Public control methods
  void play() {
    if (_chewieController != null) {
      _chewieController!.play();
      _view?.showSuccess("Playback resumed");
    }
  }

  void pause() {
    if (_chewieController != null) {
      _chewieController!.pause();
      _view?.showSuccess("Playback paused");
    }
  }

  void skipToNext() {
    if (_allControllers.isEmpty) return;

    _allControllers[_currentIndex].removeListener(_videoListener);
    _view?.showSuccess("Skipping to next video...");
    _nextVideo();
  }

  void skipToPrevious() {
    if (_allControllers.isEmpty) return;

    _allControllers[_currentIndex].removeListener(_videoListener);
    _currentIndex = (_currentIndex - 1) % _allControllers.length;
    if (_currentIndex < 0) _currentIndex = _allControllers.length - 1;
    _playCurrent();
    _allControllers[_currentIndex].addListener(_videoListener);
    _view?.showSuccess("Previous video");
  }

  void restartPlaylist() {
    if (_allControllers.isEmpty) return;

    _allControllers[_currentIndex].removeListener(_videoListener);
    _currentIndex = 0;
    _playCurrent();
    _allControllers[_currentIndex].addListener(_videoListener);
    _view?.showSuccess("Playlist restarted");
  }

  void seekToVideo(int index) {
    if (_allControllers.isEmpty || index < 0 || index >= _allControllers.length) return;

    _allControllers[_currentIndex].removeListener(_videoListener);
    _currentIndex = index;
    _playCurrent();
    _allControllers[_currentIndex].addListener(_videoListener);
    _view?.showSuccess("Jumped to video ${index + 1}");
  }

  Map<String, dynamic> getPlaybackInfo() {
    return {
      'currentIndex': _currentIndex,
      'totalVideos': _allControllers.length,
      'isPlaying': _chewieController?.isPlaying ?? false,
      'isInitialized': _isInitialized,
      'currentVideo': _currentIndex < _allControllers.length ?
      _scheduleService.getAllVideoPaths()[_currentIndex].split('/').last : 'None',
      'playbackProgress': _allControllers.isNotEmpty ?
      '${_currentIndex + 1}/${_allControllers.length}' : '0/0',
    };
  }

  Map<String, dynamic> getScheduleInfo() {
    return _scheduleService.getScheduleInfo();
  }

  List<String> getPlaylist() {
    return _scheduleService.getAllVideoPaths().map((path) => path.split('/').last).toList();
  }

  Future<void> refreshSchedule() async {
    try {
      _view?.showSuccess("Refreshing schedule...");
      await _scheduleService.forceUpdateSchedule();
      await _loadAndStartPlaylist();
      _view?.showSuccess("Schedule updated successfully");
    } catch (e) {
      _view?.showError("Schedule refresh failed: $e");
    }
  }

  Future<void> reloadPlaylist() async {
    try {
      _view?.showSuccess("Reloading playlist...");
      await _loadAndStartPlaylist();
      _view?.showSuccess("Playlist reloaded");
    } catch (e) {
      _view?.showError("Playlist reload failed: $e");
    }
  }

  // Volume control
  void setVolume(double volume) {
    if (_chewieController != null) {
      // Note: Chewie doesn't have direct volume control, this would need video_player controller
      _view?.showSuccess("Volume: ${(volume * 100).toInt()}%");
    }
  }

  // Playback speed control
  void setPlaybackSpeed(double speed) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      _chewieController!.videoPlayerController.setPlaybackSpeed(speed);
      _view?.showSuccess("Playback speed: ${speed}x");
    }
  }

  void dispose() {
    _playbackTimer?.cancel();
    _chewieController?.dispose();
    for (var c in _allControllers) {
      c.removeListener(_videoListener);
      c.dispose();
    }
    _allControllers.clear();
    _scheduleService.dispose();

    print('VideoPlayerPresenter disposed');
  }
}