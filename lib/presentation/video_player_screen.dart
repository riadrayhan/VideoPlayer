import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/storage_service.dart';
import '../services/video_schedule_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final VideoScheduleService _videoService = VideoScheduleService();
  VideoPlayerController? _videoController;

  // State variables for UI
  String _currentError = '';
  String _currentSuccess = '';
  String _videoStatus = '';
  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentVideoIndex = 0;
  int _totalVideos = 0;
  String _currentVideoName = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    // Error messages listener
    _videoService.errorStream.listen((error) async {
      if (mounted) {
        setState(() {
          _currentError = error;
          _currentSuccess = '';
        });

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _currentError == error) {
            setState(() {
              _currentError = '';
            });
          }
        });
      }
    });

    // Success messages listener
    _videoService.successStream.listen((success) {
      if (mounted) {
        setState(() {
          _currentSuccess = success;
          _currentError = '';
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && _currentSuccess == success) {
            setState(() {
              _currentSuccess = '';
            });
          }
        });
      }
    });

    // Loading state listener
    _videoService.loadingStream.listen((loading) {
      if (mounted) {
        setState(() {
          _isLoading = loading;
        });
      }
    });

    // Playlist progress listener
    _videoService.playlistProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentVideoIndex = progress['currentIndex'];
          _totalVideos = progress['totalVideos'];
          _currentVideoName = progress['currentVideo'];
          _isPlaying = progress['isPlaying'];
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _videoStatus = 'অ্যাপ্লিকেশন শুরু হচ্ছে...';
      });

      // Load schedule
      await _videoService.loadSchedule();

      // Get video paths from schedule
      final videoPaths = _videoService.getAllVideoPaths();

      if (videoPaths.isEmpty) {
        setState(() {
          _currentError = 'কোনো ভিডিও পাওয়া যায়নি। JSON ফাইল চেক করুন।';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentSuccess = '${videoPaths.length}টি ভিডিও লোড করা হয়েছে';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _currentError = 'অ্যাপ্লিকেশন শুরু করতে সমস্যা: $e';
        _isLoading = false;
      });
    }
  }

  // Clear all data and restart
  Future<void> _clearAndRestart() async {
    try {
      setState(() {
        _isLoading = true;
        _currentSuccess = 'ডাটা ক্লিয়ার করা হচ্ছে...';
      });

      await StorageService.clearAllData();
      await _videoService.dispose();

      setState(() {
        _currentSuccess = 'ডাটা ক্লিয়ার করা হয়েছে, পুনরায় শুরু করা হচ্ছে...';
      });

      await _initializePlayer();
    } catch (e) {
      setState(() {
        _currentError = 'রিসেট করতে সমস্যা: $e';
      });
    }
  }

  // Play video
  Future<void> _playVideo() async {
    try {
      if (_videoService.currentController != null) {
        await _videoService.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      setState(() {
        _currentError = 'ভিডিও চালু করতে সমস্যা: $e';
      });
    }
  }

  // Pause video
  Future<void> _pauseVideo() async {
    try {
      if (_videoService.currentController != null) {
        await _videoService.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentError = 'ভিডিও থামাতে সমস্যা: $e';
      });
    }
  }

  Widget _buildMessageOverlay() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Column(
        children: [
          // Error Message
          if (_currentError.isNotEmpty)
            _buildMessageContainer(_currentError, Colors.red),

          // Success Message
          if (_currentSuccess.isNotEmpty)
            _buildMessageContainer(_currentSuccess, Colors.green),

          // Video Status
          if (_videoStatus.isNotEmpty)
            _buildMessageContainer(_videoStatus, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMessageContainer(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.red ? Icons.error_outline :
            color == Colors.green ? Icons.check_circle : Icons.info_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ভিডিও: $_currentVideoName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_currentVideoIndex + 1}/$_totalVideos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'স্ট্যাটাস: ${_isPlaying ? 'চালু' : 'বন্ধ'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'প্লেলিস্ট: $_totalVideos ভিডিও',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            onPressed: _playVideo,
            backgroundColor: Colors.green,
            mini: true,
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pauseVideo,
            backgroundColor: Colors.orange,
            mini: true,
            child: const Icon(Icons.pause, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _clearAndRestart,
            backgroundColor: Colors.red,
            mini: true,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoService.currentController != null &&
        _videoService.currentController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoService.currentController!.value.aspectRatio,
          child: VideoPlayer(_videoService.currentController!),
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text(
              'কোনো ভিডিও পাওয়া যায়নি',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'JSON ফাইল চেক করুন বা ভিডিও অ্যাড করুন',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'লোড হচ্ছে...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player or Loading Screen
          if (_isLoading)
            _buildLoadingScreen()
          else
            _buildVideoPlayer(),

          // Messages Overlay (Error, Success, Status)
          _buildMessageOverlay(),

          // Video Information
          if (_totalVideos > 0 && !_isLoading)
            _buildVideoInfo(),

          // Control Buttons
          if (_videoService.currentController != null && !_isLoading)
            _buildControlButtons(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoService.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}