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
            _buildMessageContainer(
              _currentError,
              Colors.red,
              Icons.error_outline,
            ),

          // Success Message
          if (_currentSuccess.isNotEmpty)
            _buildMessageContainer(
              _currentSuccess,
              Colors.green,
              Icons.check_circle,
            ),

          // Video Status
          if (_videoStatus.isNotEmpty)
            _buildMessageContainer(
              _videoStatus,
              Colors.blue,
              Icons.info_outline,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContainer(String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.video_library,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentVideoName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '${_currentVideoIndex + 1}/$_totalVideos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPlaying ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isPlaying ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPlaying ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPlaying ? 'চালু' : 'বন্ধ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_music,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_totalVideos ভিডিও',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
          // Play Button
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _playVideo,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.play_arrow, size: 28),
            ),
          ),

          // Pause Button
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _pauseVideo,
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.pause, size: 28),
            ),
          ),

          // Restart Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _clearAndRestart,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.refresh, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoService.currentController != null &&
        _videoService.currentController!.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoService.currentController!.value.aspectRatio,
            child: VideoPlayer(_videoService.currentController!),
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.videocam_off,
                color: Colors.white54,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'কোনো ভিডিও পাওয়া যায়নি',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'JSON ফাইল চেক করুন বা ভিডিও অ্যাড করুন',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'লোড হচ্ছে...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ভিডিও প্লেলিস্ট প্রস্তুত করা হচ্ছে',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: Stack(
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