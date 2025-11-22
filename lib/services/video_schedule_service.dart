import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class VideoScheduleService {
  VideoPlayerController? _currentController;
  final List<String> _playlist = [];
  int _currentIndex = 0;

  final StreamController<String> _errorController = StreamController.broadcast();
  final StreamController<String> _successController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _progressController = StreamController.broadcast();

  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get successStream => _successController.stream;
  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;
  VideoPlayerController? get currentController => _currentController;

  List<String> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  Future<void> loadAllVideosFromAssets() async {
    try {
      _successController.add("Loading videos...");

      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final videoFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/videos/ads/') && key.endsWith('.mp4'))
          .toList();

      if (videoFiles.isEmpty) {
        _errorController.add("No videos found!");
        return;
      }

      _playlist.clear();
      _playlist.addAll(videoFiles);
      _playlist.sort();

      print('Found ${_playlist.length} videos: $_playlist');
      _successController.add("${_playlist.length} videos loaded");
      await _playVideo(0);
    } catch (e) {
      _errorController.add("Load failed");
      print("Error: $e");
    }
  }

  Future<void> _playVideo(int index) async {
    if (index >= _playlist.length) index = 0;
    _currentIndex = index;
    final videoPath = _playlist[index];

    await _currentController?.dispose();
    _currentController = VideoPlayerController.asset(videoPath);

    try {
      await _currentController!.initialize();
      await Future.delayed(const Duration(milliseconds: 200));

      _progressController.add({
        'forceRefresh': true,
        'currentIndex': index + 1,
        'total': _playlist.length,
        'currentVideo': path.basename(videoPath),
      });

      await _currentController!.play();
      print('Playing: ${path.basename(videoPath)}');

      _currentController!.addListener(() {
        if (_currentController!.value.isCompleted) {
          _currentController!.removeListener(() {});
          _playVideo(index + 1);
        }
      });
    } catch (e) {
      print('Error: $e');
      await Future.delayed(const Duration(seconds: 2));
      _playVideo(index + 1);
    }
  }

  Future<void> play() async => await _currentController?.play();
  Future<void> pause() async => await _currentController?.pause();
  Future<void> next() async => await _playVideo(_currentIndex + 1);
  Future<void> previous() async => await _playVideo(_currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1);

  void dispose() {
    _currentController?.dispose();
    _errorController.close();
    _successController.close();
    _progressController.close();
  }
}