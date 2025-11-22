import 'dart:async';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import '../models/schedule_models.dart';
import '../models/instruction_model.dart';
import 'JsonParserService.dart';
import 'storage_service.dart';

class VideoScheduleService {
  Schedule? _currentSchedule;
  VideoPlayerController? _currentController;
  final List<String> _currentPlaylist = [];
  int _currentVideoIndex = 0;
  bool _isPlaying = false;
  String _playlistRepeat = 'always';

  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<String> _successController = StreamController<String>.broadcast();
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _playlistProgressController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get successStream => _successController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<Map<String, dynamic>> get playlistProgressStream => _playlistProgressController.stream;

  VideoPlayerController? get currentController => _currentController;

  Future<void> loadSchedule() async {
    try {
      _loadingController.add(true);
      _successController.add('Loading schedule...');

      print('Checking for saved instructions...');

      // Try to load from storage first
      final savedInstructions = await StorageService.getSavedInstructions();

      if (savedInstructions != null && savedInstructions.isNotEmpty) {
        try {
          print('Found saved instructions, parsing...');
          final scheduleJson = json.decode(savedInstructions);
          _currentSchedule = Schedule.fromJson(scheduleJson);
          _playlistRepeat = _currentSchedule!.playlistRepeat;
          _successController.add('Saved schedule loaded successfully');
          print('Saved schedule loaded with ${_currentSchedule!.playlist.length} items');
        } catch (e) {
          print('Error parsing saved instructions: $e');
          await StorageService.clearInstructions();
          _errorController.add('Corrupted saved schedule, loading from assets...');
          await _loadFromAssets();
        }
      } else {
        print('No saved instructions found, loading from assets...');
        await _loadFromAssets();
      }

      // Start playback if schedule is available
      if (_currentSchedule != null) {
        await _startPlayback();
      } else {
        _errorController.add('Failed to load any schedule');
      }

    } catch (e) {
      _errorController.add('Schedule load error: $e');
      print('Critical error in loadSchedule: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      print('Loading instructions from assets...');
      final instructionModel = await JsonParserService.parseInstructionsFromAssets('assets/instructions.json');

      if (instructionModel != null && instructionModel.instructions.isNotEmpty) {
        print('Successfully loaded instructions from assets');
        await _createScheduleFromInstruction(instructionModel);
        _successController.add('Schedule loaded from assets');
      } else {
        print('No instructions in assets, using default...');
        await _useDefaultSchedule();
      }
    } catch (e) {
      print('Error loading from assets: $e');
      await _useDefaultSchedule();
    }
  }

  Future<void> _createScheduleFromInstruction(InstructionModel instructionModel) async {
    try {
      for (final instruction in instructionModel.instructions) {
        if (instruction.type == 'update_schedule') {
          print('Creating schedule from instruction data...');
          _currentSchedule = Schedule(
            playlistRepeat: instruction.data.playlistRepeat,
            playlist: instruction.data.playlist,
          );

          _playlistRepeat = instruction.data.playlistRepeat;

          // Save to storage for next time
          await _saveScheduleToStorage(_currentSchedule!);
          print('Schedule created and saved with ${instruction.data.playlist.length} items');
          break;
        }
      }

      // If no update_schedule instruction found, use default
      if (_currentSchedule == null) {
        print('No update_schedule instruction found, using default');
        await _useDefaultSchedule();
      }
    } catch (e) {
      print('Error creating schedule from instruction: $e');
      await _useDefaultSchedule();
    }
  }

  Future<void> _useDefaultSchedule() async {
    try {
      print('Creating default schedule...');
      _currentSchedule = Schedule(
        playlistRepeat: 'always',
        playlist: [
          ScheduleItem(
            folder: 'ads',
            files: ['20251110_162219_432380_5QayAWR5Fq2omQRMb8ab.mp4',"sample1.mp4", "sample2.mp4"],
            adId: 1,
            repeat: 1,
            sequence: 1,
          ),
        ],
      );

      _playlistRepeat = 'always';
      await _saveScheduleToStorage(_currentSchedule!);
      _successController.add('Default schedule loaded');
      print('Default schedule created with ${_currentSchedule!.playlist.length} items');
    } catch (e) {
      _errorController.add('Failed to create default schedule: $e');
      print('Error creating default schedule: $e');
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
      _errorController.add('No schedule available for playback');
      return;
    }

    try {
      print('Starting playback with schedule...');
      _currentPlaylist.clear();
      final sortedPlaylist = List<ScheduleItem>.from(_currentSchedule!.playlist)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

      // Build the playlist with correct paths
      for (var item in sortedPlaylist) {
        for (var file in item.files) {
          // JSON says folder is "ads" but files are in "videos/ads"
          // So we need to build the path as: assets/videos/ads/filename.mp4
          final videoPath = 'assets/videos/${item.folder}/$file';
          for (int i = 0; i < item.repeat; i++) {
            _currentPlaylist.add(videoPath);
          }
          print('Added to playlist: $videoPath (repeat: ${item.repeat})');
        }
      }

      print('Playlist built with ${_currentPlaylist.length} videos: $_currentPlaylist');

      if (_currentPlaylist.isNotEmpty) {
        await _playVideo(0);
        _successController.add('Video playback started with ${_currentPlaylist.length} videos');
      } else {
        _errorController.add('No videos in playlist');
      }
    } catch (e) {
      _errorController.add('Playback start error: $e');
      print('Error starting playback: $e');
    }
  }

  Future<void> _playVideo(int index) async {
    if (index >= _currentPlaylist.length) {
      // Handle end of playlist based on repeat setting
      if (_playlistRepeat == 'always' && _currentPlaylist.isNotEmpty) {
        print('Playlist repeating, restarting from beginning');
        await _playVideo(0); // Restart from beginning
      } else {
        _successController.add('Playlist completed');
      }
      return;
    }

    _currentVideoIndex = index;
    final videoPath = _currentPlaylist[index];

    try {
      await _disposeCurrentController();
      print('Loading video: $videoPath');

      _currentController = VideoPlayerController.asset(videoPath)
        ..setLooping(false)
        ..addListener(_videoListener);

      await _currentController!.initialize();

      // Check if video is properly initialized
      if (!_currentController!.value.isInitialized) {
        throw Exception('Video failed to initialize');
      }

      print('Video initialized successfully:');
      print('- Duration: ${_currentController!.value.duration}');
      print('- Size: ${_currentController!.value.size}');
      print('- Aspect Ratio: ${_currentController!.value.aspectRatio}');

      await _currentController!.play();
      _isPlaying = true;

      _updatePlaylistProgress();
      print('Video playing: ${videoPath.split('/').last}');
    } catch (e) {
      _errorController.add('Cannot load video: ${videoPath.split('/').last} - ${e.toString()}');
      print('Error loading video $videoPath: $e');

      // Skip to next video after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (_currentPlaylist.length > index + 1) {
        await _playVideo(index + 1);
      } else if (_playlistRepeat == 'always' && _currentPlaylist.isNotEmpty) {
        await _playVideo(0);
      }
    }
  }

  void _videoListener() {
    if (_currentController != null &&
        _currentController!.value.isInitialized &&
        _currentController!.value.isCompleted) {
      print('Video completed, playing next...');
      _playNextVideo();
    }
  }

  Future<void> _playNextVideo() async {
    final nextIndex = _currentVideoIndex + 1;
    print('Moving to next video: $nextIndex/${_currentPlaylist.length}');

    if (nextIndex < _currentPlaylist.length) {
      await _playVideo(nextIndex);
    } else {
      // End of playlist - handle based on repeat setting
      if (_playlistRepeat == 'always') {
        print('End of playlist, restarting...');
        await _playVideo(0); // Restart from beginning
      } else {
        _successController.add('Playlist completed');
      }
    }
  }

  void _updatePlaylistProgress() {
    if (_currentVideoIndex < _currentPlaylist.length) {
      _playlistProgressController.add({
        'currentIndex': _currentVideoIndex,
        'totalVideos': _currentPlaylist.length,
        'currentVideo': _currentPlaylist[_currentVideoIndex].split('/').last,
        'isPlaying': _isPlaying,
      });
    }
  }

  // Control methods
  Future<void> play() async {
    if (_currentController != null && _currentController!.value.isInitialized) {
      await _currentController!.play();
      _isPlaying = true;
      _updatePlaylistProgress();
      _successController.add('Playback resumed');
    } else {
      _errorController.add('No video controller available');
    }
  }

  Future<void> pause() async {
    if (_currentController != null && _currentController!.value.isInitialized) {
      await _currentController!.pause();
      _isPlaying = false;
      _updatePlaylistProgress();
      _successController.add('Playback paused');
    } else {
      _errorController.add('No video controller available');
    }
  }

  // Get all video paths
  List<String> getAllVideoPaths() {
    return List.from(_currentPlaylist);
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
      'currentVideoIndex': _currentVideoIndex,
      'isPlaying': _isPlaying,
    };
  }

  Schedule? getCurrentSchedule() {
    return _currentSchedule;
  }

  Future<void> forceUpdateSchedule() async {
    try {
      _loadingController.add(true);
      _successController.add('Force updating schedule...');

      // Clear current data
      await _disposeCurrentController();
      _currentPlaylist.clear();
      _currentSchedule = null;
      _playlistRepeat = 'always';

      // Clear storage
      await StorageService.clearInstructions();

      // Load fresh from JSON
      await _loadFromAssets();

      if (_currentSchedule != null) {
        await _startPlayback();
        _successController.add('Schedule updated successfully');
      } else {
        _errorController.add('Cannot load new schedule');
      }
    } catch (e) {
      _errorController.add('Schedule update error: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> _disposeCurrentController() async {
    if (_currentController != null) {
      _currentController!.removeListener(_videoListener);
      await _currentController!.dispose();
      _currentController = null;
    }
    _isPlaying = false;
  }

  Future<void> dispose() async {
    await _disposeCurrentController();
    await _errorController.close();
    await _successController.close();
    await _loadingController.close();
    await _playlistProgressController.close();
  }
}