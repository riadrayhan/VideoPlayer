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
  VideoScheduleService _videoService = VideoScheduleService();
  VideoPlayerController? _videoController;

  // State variables for UI
  String _currentError = '';
  String _currentSuccess = '';
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

        Future.delayed(const Duration(seconds: 3), () {
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
      });

      // Load schedule
      await _videoService.loadSchedule();

      // Get video paths from schedule
      final videoPaths = _videoService.getAllVideoPaths();

      if (videoPaths.isEmpty) {
        setState(() {
          _currentError = 'No videos found. Please check JSON file.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentSuccess = '${videoPaths.length} videos loaded successfully';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _currentError = 'Failed to start application: $e';
        _isLoading = false;
      });
    }
  }

  // Clear all data and restart
  Future<void> _clearAndRestart() async {
    try {
      setState(() {
        _isLoading = true;
        _currentSuccess = 'Clearing data...';
      });

      // Dispose old service completely
      await _videoService.dispose();

      // Clear storage
      await StorageService.clearAllData();

      setState(() {
        _currentSuccess = 'Data cleared, restarting...';
      });

      // Wait a bit for cleanup
      await Future.delayed(const Duration(milliseconds: 500));

      // Create new service instance
      _videoService = VideoScheduleService();

      // Re-setup listeners
      _setupStreamListeners();

      // Reinitialize
      await _initializePlayer();

      setState(() {
        _currentSuccess = 'Application restarted successfully';
      });

    } catch (e) {
      setState(() {
        _currentError = 'Reset failed: $e';
        _isLoading = false;
      });
    }
  }

  // Play video
  Future<void> _playVideo() async {
    try {
      if (_videoService.currentController == null) {
        setState(() {
          _currentError = 'No video controller available';
        });
        return;
      }

      if (!_videoService.currentController!.value.isInitialized) {
        setState(() {
          _currentError = 'Video not initialized yet';
        });
        return;
      }

      // Check if video is already playing
      if (_videoService.currentController!.value.isPlaying) {
        setState(() {
          _currentSuccess = 'Video is already playing';
          _isPlaying = true;
        });
        return;
      }

      await _videoService.play();

      setState(() {
        _isPlaying = true;
        _currentSuccess = 'Playback resumed';
      });

    } catch (e) {
      setState(() {
        _currentError = 'Failed to play video: $e';
      });
    }
  }

  // Pause video
  Future<void> _pauseVideo() async {
    try {
      if (_videoService.currentController == null) {
        setState(() {
          _currentError = 'No video controller available';
        });
        return;
      }

      if (!_videoService.currentController!.value.isInitialized) {
        setState(() {
          _currentError = 'Video not initialized yet';
        });
        return;
      }

      // Check if video is already paused
      if (!_videoService.currentController!.value.isPlaying) {
        setState(() {
          _currentSuccess = 'Video is already paused';
          _isPlaying = false;
        });
        return;
      }

      await _videoService.pause();

      setState(() {
        _isPlaying = false;
        _currentSuccess = 'Playback paused';
      });

    } catch (e) {
      setState(() {
        _currentError = 'Failed to pause video: $e';
      });
    }
  }

  Widget _buildBottomMessageOverlay() {
    return Positioned(
      bottom: 140,
      left: 24,
      right: 24,
      child: Column(
        children: [
          // Error Message
          if (_currentError.isNotEmpty)
            _buildBottomMessageContainer(
              _currentError,
              const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
              ),
              Icons.error_outline_rounded,
              const Color(0xFFFF6B6B),
            ),

          // Success Message
          if (_currentSuccess.isNotEmpty)
            _buildBottomMessageContainer(
              _currentSuccess,
              const LinearGradient(
                colors: [Color(0xFF51CF66), Color(0xFF37B24D)],
              ),
              Icons.check_circle_outline_rounded,
              const Color(0xFF51CF66),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomMessageContainer(
      String message,
      Gradient gradient,
      IconData icon,
      Color shadowColor,
      ) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(message),
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoInfo() {
    return Positioned(
      bottom: 220,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.black.withOpacity(0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentVideoName.isNotEmpty ? _currentVideoName : 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DABF7), Color(0xFF339AF0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4DABF7).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '$_totalVideos > 0 ? ${_currentVideoIndex + 1} : 0/$_totalVideos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isPlaying
                            ? [const Color(0xFF51CF66), const Color(0xFF37B24D)]
                            : [const Color(0xFFFFA94D), const Color(0xFFFF8C42)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isPlaying ? const Color(0xFF51CF66) : const Color(0xFFFFA94D)).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPlaying ? 'PLAYING' : 'PAUSED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCC5DE8), Color(0xFFAD5DD7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCC5DE8).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_library_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalVideos VIDEOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
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
      bottom: 30,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play Button
          _buildControlButton(
            onPressed: _playVideo,
            gradient: const LinearGradient(
              colors: [Color(0xFF51CF66), Color(0xFF37B24D)],
            ),
            icon: Icons.play_arrow_rounded,
            shadowColor: const Color(0xFF51CF66),
            label: 'PLAY',
          ),
          const SizedBox(width: 16),

          // Pause Button
          _buildControlButton(
            onPressed: _pauseVideo,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA94D), Color(0xFFFF8C42)],
            ),
            icon: Icons.pause_rounded,
            shadowColor: const Color(0xFFFFA94D),
            label: 'PAUSE',
          ),
          const SizedBox(width: 16),

          // Restart Button
          _buildControlButton(
            onPressed: _clearAndRestart,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
            ),
            icon: Icons.refresh_rounded,
            shadowColor: const Color(0xFFFF6B6B),
            label: 'RESTART',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required Gradient gradient,
    required IconData icon,
    required Color shadowColor,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoService.currentController != null &&
        _videoService.currentController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoService.currentController!.value.size.width,
            height: _videoService.currentController!.value.size.height,
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.videocam_off_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 100,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Video Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Please check your JSON file or add videos to the playlist',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.3,
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparing video playlist',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F0F),
              const Color(0xFF1A1A1A),
              const Color(0xFF0F0F0F),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Video Player or Loading Screen (Fullscreen)
            if (_isLoading)
              _buildLoadingScreen()
            else
              _buildVideoPlayer(),

            // Video Information (Bottom - Above Messages)
            if (_totalVideos > 0 && !_isLoading)
              _buildVideoInfo(),

            // Messages Overlay (Bottom - Above Controls)
            if (!_isLoading)
              _buildBottomMessageOverlay(),

            // Control Buttons (Bottom)
            if (!_isLoading)
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