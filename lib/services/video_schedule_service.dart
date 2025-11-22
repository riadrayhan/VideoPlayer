import 'dart:async';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import '../models/schedule_models.dart';
import 'asset_video_loader.dart';
import 'storage_service.dart';

class VideoScheduleService {
  Schedule? _currentSchedule;
  VideoPlayerController? _currentController;
  final List<String> _currentPlaylist = [];
  int _currentVideoIndex = 0;
  bool _isPlaying = false;
  bool _isDisposed = false;

  StreamController<String>? _errorController;
  StreamController<String>? _successController;
  StreamController<bool>? _loadingController;
  StreamController<Map<String, dynamic>>? _playlistProgressController;

  VideoScheduleService() {
    _initializeControllers();
  }

  void _initializeControllers() {
    _errorController = StreamController<String>.broadcast();
    _successController = StreamController<String>.broadcast();
    _loadingController = StreamController<bool>.broadcast();
    _playlistProgressController = StreamController<Map<String, dynamic>>.broadcast();
  }

  Stream<String> get errorStream => _errorController!.stream;
  Stream<String> get successStream => _successController!.stream;
  Stream<bool> get loadingStream => _loadingController!.stream;
  Stream<Map<String, dynamic>> get playlistProgressStream => _playlistProgressController!.stream;

  VideoPlayerController? get currentController => _currentController;

  void _addError(String message) {
    if (!_isDisposed && _errorController != null && !_errorController!.isClosed) {
      _errorController!.add(message);
    }
  }

  void _addSuccess(String message) {
    if (!_isDisposed && _successController != null && !_successController!.isClosed) {
      _successController!.add(message);
    }
  }

  void _addLoading(bool loading) {
    if (!_isDisposed && _loadingController != null && !_loadingController!.isClosed) {
      _loadingController!.add(loading);
    }
  }

  void _addProgress(Map<String, dynamic> progress) {
    if (!_isDisposed && _playlistProgressController != null && !_playlistProgressController!.isClosed) {
      _playlistProgressController!.add(progress);
    }
  }

  // Load schedule with detailed debugging
  Future<void> loadSchedule() async {
    try {
      _addLoading(true);
      _addSuccess('Loading schedule...');

      print('=== DEBUG: Schedule Loading Started ===');

      // Try to load from storage first
      final savedInstructions = await StorageService.getSavedInstructions();
      print('Storage check: ${savedInstructions != null ? 'Found saved instructions' : 'No saved instructions'}');

      if (savedInstructions != null && savedInstructions.isNotEmpty) {
        try {
          print('Saved instructions length: ${savedInstructions.length}');
          final scheduleJson = json.decode(savedInstructions);
          _currentSchedule = Schedule.fromJson(scheduleJson);
          _addSuccess('Loaded saved schedule');
          print('Loaded from storage: ${_currentSchedule!.playlist.length} playlist items');
        } catch (e) {
          print('Error parsing saved instructions: $e');
          await StorageService.clearInstructions();
        }
      }

      // If no schedule in storage, load from assets
      if (_currentSchedule == null) {
        print('Loading default schedule from assets...');
        await _loadDefaultSchedule();
      } else {
        print('Using schedule from storage');
      }

      // Start playback if schedule is available
      if (_currentSchedule != null) {
        print('Starting playback...');
        await _startPlayback();
      } else {
        print('No schedule available after all attempts');
        _addError('No schedule found. Please check JSON file.');
      }

      print('=== DEBUG: Schedule Loading Completed ===');

    } catch (e) {
      print('Schedule load error: $e');
      _addError('Failed to load schedule: $e');
    } finally {
      _addLoading(false);
    }
  }

  Future<void> _loadDefaultSchedule() async {
    try {
      print('Loading JSON from assets/instructions.json...');

      try {
        final instructionModel = await JsonParserService.parseInstructionsFromAssets('assets/instructions.json');

        if (instructionModel == null) {
          print('JSON Parser returned null');
          _addError('Failed to parse JSON file');
          return;
        }

        print('JSON loaded successfully: ${instructionModel.instructions.length} instructions found');

        if (instructionModel.instructions.isEmpty) {
          print('No instructions in JSON file');
          _addError('No instructions found in JSON file');
          return;
        }

        bool foundSchedule = false;
        for (final instruction in instructionModel.instructions) {
          print('Checking instruction: ${instruction.type}');

          if (instruction.type == 'update_schedule') {
            print('Found update_schedule instruction');

            _currentSchedule = Schedule(
              playlistRepeat: instruction.data.playlistRepeat,
              playlist: instruction.data.playlist.map((item) => PlaylistItem(
                folder: item.folder,
                files: item.files,
                adId: item.adId,
                repeat: item.repeat,
                sequence: item.sequence,
              )).toList(),
            );

            print('Schedule created with:');
            print('   - Playlist repeat: ${_currentSchedule!.playlistRepeat}');
            print('   - Playlist items: ${_currentSchedule!.playlist.length}');

            for (var item in _currentSchedule!.playlist) {
              print('     Folder: ${item.folder}');
              print('     Files: ${item.files}');
              print('     Repeat: ${item.repeat}');
              print('     Sequence: ${item.sequence}');
            }

            // Save to storage
            await _saveScheduleToStorage(_currentSchedule!);
            _addSuccess('Default schedule loaded');
            foundSchedule = true;
            break;
          }
        }

        if (!foundSchedule) {
          print('No update_schedule instruction found in JSON');
          _addError('No update_schedule instruction found in JSON');
        }

      } catch (e) {
        print('Error accessing JSON file: $e');
        _addError('Failed to access JSON file: $e');
      }

    } catch (e) {
      print('Default schedule load error: $e');
      _addError('Failed to load default schedule: $e');
    }
  }

  Future<void> _saveScheduleToStorage(Schedule schedule) async {
    try {
      final scheduleJson = {
        'playlist_repeat': schedule.playlistRepeat,
        'playlist': schedule.playlist.map((item) => item.toJson()).toList(),
      };

      await StorageService.saveInstructions(json.encode(scheduleJson));
      print('Schedule saved to storage');
    } catch (e) {
      print('Error saving to storage: $e');
    }
  }

  Future<void> _startPlayback() async {
    if (_currentSchedule == null) {
      print('Cannot start playback: No schedule');
      return;
    }

    print('Building playlist...');

    // Build playlist
    _currentPlaylist.clear();
    final sortedPlaylist = List<PlaylistItem>.from(_currentSchedule!.playlist)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    for (var item in sortedPlaylist) {
      for (var file in item.files) {
        // Build correct video path - folder already contains "videos" or full path
        String videoPath;
        if (item.folder.startsWith('videos')) {
          videoPath = 'assets/${item.folder}/$file';
        } else {
          videoPath = 'assets/videos/${item.folder}/$file';
        }

        for (int i = 0; i < item.repeat; i++) {
          _currentPlaylist.add(videoPath);
          print('Added to playlist: $videoPath');
        }
      }
    }

    print('Total videos in playlist: ${_currentPlaylist.length}');

    if (_currentPlaylist.isNotEmpty) {
      await _playVideo(0);
      _addSuccess('Video playback started');
    } else {
      print('Playlist is empty');
      _addError('No videos in playlist');
    }
  }

  Future<void> _playVideo(int index) async {
    if (_isDisposed) return;
    if (index >= _currentPlaylist.length) return;

    _currentVideoIndex = index;
    final videoPath = _currentPlaylist[index];

    print('==========================================');
    print('Attempting to play video:');
    print('Path: $videoPath');
    print('Index: $index / ${_currentPlaylist.length}');
    print('==========================================');

    try {
      await _disposeCurrentController();

      print('Creating VideoPlayerController for: $videoPath');
      _currentController = VideoPlayerController.asset(videoPath)
        ..setLooping(false);

      // Add listener for video completion
      _currentController!.addListener(_videoListener);

      print('Initializing video controller...');
      await _currentController!.initialize();

      print('Video initialized successfully');
      print('Video duration: ${_currentController!.value.duration}');
      print('Video size: ${_currentController!.value.size}');

      print('Starting video playback...');
      await _currentController!.play();
      _isPlaying = true;

      _updatePlaylistProgress();
      _addSuccess('Now playing: ${videoPath.split('/').last}');
      print('✓ Video playing successfully: ${videoPath.split('/').last}');
      print('==========================================');
    } catch (e) {
      print('==========================================');
      print('✗ VIDEO LOAD ERROR:');
      print('Path: $videoPath');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      print('==========================================');

      _addError('Failed to load: ${videoPath.split('/').last}');

      // Skip to next video after delay
      await Future.delayed(const Duration(seconds: 2));
      if (!_isDisposed && _currentVideoIndex + 1 < _currentPlaylist.length) {
        print('Skipping to next video...');
        await _playVideo(_currentVideoIndex + 1);
      } else {
        print('No more videos to try');
        _addError('Unable to play any videos. Check video files and pubspec.yaml');
      }
    }
  }

  void _videoListener() {
    if (_isDisposed || _currentController == null) return;

    if (_currentController!.value.isInitialized &&
        _currentController!.value.position >= _currentController!.value.duration &&
        _isPlaying) {
      // Video completed, play next
      print('Video completed, moving to next...');
      _playNextVideo();
    }
  }

  Future<void> _playNextVideo() async {
    if (_isDisposed) return;
    final nextIndex = (_currentVideoIndex + 1) % _currentPlaylist.length;
    await _playVideo(nextIndex);
  }

  void _updatePlaylistProgress() {
    if (_isDisposed) return;
    _addProgress({
      'currentIndex': _currentVideoIndex,
      'totalVideos': _currentPlaylist.length,
      'currentVideo': _currentPlaylist.isNotEmpty ? _currentPlaylist[_currentVideoIndex].split('/').last : '',
      'isPlaying': _isPlaying,
    });
  }

  // Control methods
  Future<void> play() async {
    if (_isDisposed) return;
    if (_currentController != null && _currentController!.value.isInitialized) {
      await _currentController!.play();
      _isPlaying = true;
      _updatePlaylistProgress();
    }
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    if (_currentController != null && _currentController!.value.isInitialized) {
      await _currentController!.pause();
      _isPlaying = false;
      _updatePlaylistProgress();
    }
  }

  // Navigate to specific video
  Future<void> playVideoAtIndex(int index) async {
    if (_isDisposed) return;
    if (index >= 0 && index < _currentPlaylist.length) {
      await _playVideo(index);
    }
  }

  // Get current video index
  int getCurrentIndex() {
    return _currentVideoIndex;
  }

  // Get all video paths
  List<String> getAllVideoPaths() {
    return _currentPlaylist;
  }

  // Get schedule information
  Map<String, dynamic> getScheduleInfo() {
    if (_currentSchedule == null) {
      return {'hasSchedule': false};
    }

    return {
      'hasSchedule': true,
      'playlistRepeat': _currentSchedule!.playlistRepeat,
      'totalVideos': _currentPlaylist.length,
      'totalItems': _currentSchedule!.playlist.length,
    };
  }

  Schedule? getCurrentSchedule() {
    return _currentSchedule;
  }

  Future<void> forceUpdateSchedule() async {
    if (_isDisposed) return;

    try {
      _addLoading(true);
      _addSuccess('Force updating schedule...');

      // Clear current data
      await _disposeCurrentController();
      _currentPlaylist.clear();
      _currentSchedule = null;

      // Clear storage
      await StorageService.clearInstructions();

      // Load fresh from JSON
      await _loadDefaultSchedule();

      if (_currentSchedule != null) {
        await _startPlayback();
        _addSuccess('Schedule updated successfully');
      } else {
        _addError('Failed to load new schedule');
      }
    } catch (e) {
      _addError('Failed to update schedule: $e');
    } finally {
      _addLoading(false);
    }
  }

  Future<void> _disposeCurrentController() async {
    if (_currentController != null) {
      try {
        _currentController!.removeListener(_videoListener);
        await _currentController!.pause();
        await _currentController!.dispose();
      } catch (e) {
        print('Error disposing controller: $e');
      }
      _currentController = null;
    }
    _isPlaying = false;
  }

  Future<void> dispose() async {
    _isDisposed = true;

    await _disposeCurrentController();

    // Close all stream controllers safely
    await _errorController?.close();
    await _successController?.close();
    await _loadingController?.close();
    await _playlistProgressController?.close();

    _errorController = null;
    _successController = null;
    _loadingController = null;
    _playlistProgressController = null;
  }
}