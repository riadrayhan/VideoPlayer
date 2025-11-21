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

  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<String> _successController = StreamController<String>.broadcast();
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _playlistProgressController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get successStream => _successController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<Map<String, dynamic>> get playlistProgressStream => _playlistProgressController.stream;

  VideoPlayerController? get currentController => _currentController;

  // Load schedule with detailed debugging
  Future<void> loadSchedule() async {
    try {
      _loadingController.add(true);
      _successController.add('সিডিউল লোড করা হচ্ছে...');

      print('=== DEBUG: Schedule Loading Started ===');

      // Try to load from storage first
      final savedInstructions = await StorageService.getSavedInstructions();
      print('📦 Storage check: ${savedInstructions != null ? 'Found saved instructions' : 'No saved instructions'}');

      if (savedInstructions != null && savedInstructions.isNotEmpty) {
        try {
          print('📁 Saved instructions length: ${savedInstructions.length}');
          final scheduleJson = json.decode(savedInstructions);
          _currentSchedule = Schedule.fromJson(scheduleJson);
          _successController.add('সেভ করা সিডিউল লোড করা হয়েছে');
          print('✅ Loaded from storage: ${_currentSchedule!.playlist.length} playlist items');
        } catch (e) {
          print('❌ Error parsing saved instructions: $e');
          await StorageService.clearInstructions();
        }
      }

      // If no schedule in storage, load from assets
      if (_currentSchedule == null) {
        print('🔄 Loading default schedule from assets...');
        await _loadDefaultSchedule();
      } else {
        print('🎯 Using schedule from storage');
      }

      // Start playback if schedule is available
      if (_currentSchedule != null) {
        print('🎬 Starting playback...');
        await _startPlayback();
      } else {
        print('❌ No schedule available after all attempts');
        _errorController.add('কোনো সিডিউল পাওয়া যায়নি। JSON ফাইল চেক করুন।');
      }

      print('=== DEBUG: Schedule Loading Completed ===');

    } catch (e) {
      print('❌ Schedule load error: $e');
      _errorController.add('সিডিউল লোড করতে সমস্যা: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> _loadDefaultSchedule() async {
    try {
      print('📂 Loading JSON from assets/instructions.json...');

      // Test if we can access the file
      try {
        final instructionModel = await JsonParserService.parseInstructionsFromAssets('assets/instructions.json');

        if (instructionModel == null) {
          print('❌ JSON Parser returned null');
          _errorController.add('JSON ফাইল পার্স করতে সমস্যা');
          return;
        }

        print('✅ JSON loaded successfully: ${instructionModel.instructions.length} instructions found');

        if (instructionModel.instructions.isEmpty) {
          print('❌ No instructions in JSON file');
          _errorController.add('JSON ফাইলে কোনো নির্দেশনা নেই');
          return;
        }

        bool foundSchedule = false;
        for (final instruction in instructionModel.instructions) {
          print('🔍 Checking instruction: ${instruction.type}');

          if (instruction.type == 'update_schedule') {
            print('🎯 Found update_schedule instruction');

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

            print('📋 Schedule created with:');
            print('   - Playlist repeat: ${_currentSchedule!.playlistRepeat}');
            print('   - Playlist items: ${_currentSchedule!.playlist.length}');

            for (var item in _currentSchedule!.playlist) {
              print('     📁 Folder: ${item.folder}');
              print('     📄 Files: ${item.files}');
              print('     🔁 Repeat: ${item.repeat}');
              print('     🔢 Sequence: ${item.sequence}');
            }

            // Save to storage
            await _saveScheduleToStorage(_currentSchedule!);
            _successController.add('ডিফল্ট সিডিউল লোড করা হয়েছে');
            foundSchedule = true;
            break;
          }
        }

        if (!foundSchedule) {
          print('❌ No update_schedule instruction found in JSON');
          _errorController.add('JSON ফাইলে update_schedule নির্দেশনা নেই');
        }

      } catch (e) {
        print('❌ Error accessing JSON file: $e');
        _errorController.add('JSON ফাইল এক্সেস করতে সমস্যা: $e');
      }

    } catch (e) {
      print('❌ Default schedule load error: $e');
      _errorController.add('ডিফল্ট সিডিউল লোড করতে সমস্যা: $e');
    }
  }

  // Rest of the methods remain the same as previous...
  Future<void> _saveScheduleToStorage(Schedule schedule) async {
    try {
      final scheduleJson = {
        'playlist_repeat': schedule.playlistRepeat,
        'playlist': schedule.playlist.map((item) => item.toJson()).toList(),
      };

      await StorageService.saveInstructions(json.encode(scheduleJson));
      print('💾 Schedule saved to storage');
    } catch (e) {
      print('❌ Error saving to storage: $e');
    }
  }

  Future<void> _startPlayback() async {
    if (_currentSchedule == null) {
      print('❌ Cannot start playback: No schedule');
      return;
    }

    print('🎵 Building playlist...');

    // Build playlist
    _currentPlaylist.clear();
    final sortedPlaylist = List<PlaylistItem>.from(_currentSchedule!.playlist)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    for (var item in sortedPlaylist) {
      for (var file in item.files) {
        final videoPath = 'assets/${item.folder}/$file';
        for (int i = 0; i < item.repeat; i++) {
          _currentPlaylist.add(videoPath);
          print('➕ Added to playlist: $videoPath');
        }
      }
    }

    print('🎯 Total videos in playlist: ${_currentPlaylist.length}');

    if (_currentPlaylist.isNotEmpty) {
      await _playVideo(0);
      _successController.add('ভিডিও প্লেব্যাক শুরু হয়েছে');
    } else {
      print('❌ Playlist is empty');
      _errorController.add('প্লেলিস্টে কোনো ভিডিও নেই');
    }
  }

  Future<void> _playVideo(int index) async {
    if (index >= _currentPlaylist.length) return;

    _currentVideoIndex = index;
    final videoPath = _currentPlaylist[index];

    print('🎥 Playing video: $videoPath (Index: $index)');

    try {
      await _disposeCurrentController();

      _currentController = VideoPlayerController.asset(videoPath)
        ..setLooping(false)
        ..addListener(_videoListener);

      await _currentController!.initialize();
      await _currentController!.play();
      _isPlaying = true;

      _updatePlaylistProgress();
      _successController.add('ভিডিও চালু হয়েছে: ${videoPath.split('/').last}');
      print('✅ Video playing successfully: ${videoPath.split('/').last}');
    } catch (e) {
      print('❌ Video load error: $videoPath - $e');
      _errorController.add('ভিডিও লোড করতে পারছি না: ${videoPath.split('/').last}');

      // Skip to next video
      await Future.delayed(const Duration(seconds: 2));
      if (_currentVideoIndex + 1 < _currentPlaylist.length) {
        await _playVideo(_currentVideoIndex + 1);
      }
    }
  }

  void _videoListener() {
    if (_currentController != null &&
        _currentController!.value.isInitialized &&
        !_currentController!.value.isPlaying &&
        _isPlaying) {
      _playNextVideo();
    }
  }

  Future<void> _playNextVideo() async {
    final nextIndex = (_currentVideoIndex + 1) % _currentPlaylist.length;
    await _playVideo(nextIndex);
  }

  void _updatePlaylistProgress() {
    _playlistProgressController.add({
      'currentIndex': _currentVideoIndex,
      'totalVideos': _currentPlaylist.length,
      'currentVideo': _currentPlaylist[_currentVideoIndex].split('/').last,
      'isPlaying': _isPlaying,
    });
  }

  // Control methods
  Future<void> play() async {
    if (_currentController != null && _currentController!.value.isInitialized) {
      await _currentController!.play();
      _isPlaying = true;
      _updatePlaylistProgress();
    }
  }

  Future<void> pause() async {
    if (_currentController != null && _currentController!.value.isInitialized) {
      await _currentController!.pause();
      _isPlaying = false;
      _updatePlaylistProgress();
    }
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
    try {
      _loadingController.add(true);
      _successController.add('সিডিউল ফোর্স আপডেট করা হচ্ছে...');

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
        _successController.add('সিডিউল সফলভাবে আপডেট করা হয়েছে');
      } else {
        _errorController.add('নতুন সিডিউল লোড করতে সমস্যা');
      }
    } catch (e) {
      _errorController.add('সিডিউল আপডেট করতে সমস্যা: $e');
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