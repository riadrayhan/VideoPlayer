import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import '../presenters/video_player_presenter.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> implements VideoPlayerView {
  final VideoPlayerPresenter _presenter = VideoPlayerPresenter();

  // State variables for UI
  String _currentError = '';
  String _currentSuccess = '';
  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentVideoIndex = 0;
  int _totalVideos = 0;
  String _currentVideoName = '';
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _presenter.attachView(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isLoading = true;
        _currentSuccess = 'Initializing video player...';
      });

      await _presenter.init();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentError = 'Initialization failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void showError(String message) {
    if (!mounted) return;

    setState(() {
      _currentError = message;
      _currentSuccess = '';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentError == message) {
        setState(() {
          _currentError = '';
        });
      }
    });
  }

  @override
  void showSuccess(String message) {
    if (!mounted) return;

    setState(() {
      _currentSuccess = message;
      _currentError = '';
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentSuccess == message) {
        setState(() {
          _currentSuccess = '';
        });
      }
    });
  }

  @override
  void updateVideo(ChewieController chewieController) {
    if (!mounted) return;

    // Dispose old controller
    _chewieController?.dispose();

    setState(() {
      _chewieController = chewieController;
      _isPlaying = true;
    });
  }

  @override
  void updatePlaybackInfo(int currentIndex, int totalVideos, String currentVideo) {
    if (!mounted) return;

    setState(() {
      _currentVideoIndex = currentIndex;
      _totalVideos = totalVideos;
      _currentVideoName = currentVideo;
    });
  }

  @override
  BuildContext get context => super.context;

  // Control methods
  Future<void> _playVideo() async {
    _presenter.play();
  }

  Future<void> _pauseVideo() async {
    _presenter.pause();
  }

  Future<void> _skipToNext() async {
    _presenter.skipToNext();
  }

  Future<void> _skipToPrevious() async {
    _presenter.skipToPrevious();
  }

  Future<void> _restartPlaylist() async {
    _presenter.restartPlaylist();
  }

  Future<void> _refreshSchedule() async {
    setState(() {
      _isLoading = true;
      _currentSuccess = 'Refreshing schedule...';
    });

    await _presenter.refreshSchedule();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTopHeaderBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isPlaying
                        ? [const Color(0xFF00D4AA), const Color(0xFF00B894)]
                        : [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Play Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),

              // Now Playing Text
              const Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),

              // Video Name
              Expanded(
                child: Text(
                  _currentVideoName.isNotEmpty ? _currentVideoName : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // Progress Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${_currentVideoIndex}/$_totalVideos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          _buildControlButton(
            onPressed: _skipToPrevious,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            icon: Icons.skip_previous_rounded,
            shadowColor: const Color(0xFF667EEA),
            label: 'PREV',
          ),
          const SizedBox(width: 16),

          // Play Button
          _buildControlButton(
            onPressed: _playVideo,
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
            ),
            icon: Icons.play_arrow_rounded,
            shadowColor: const Color(0xFF00D4AA),
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

          // Next Button
          _buildControlButton(
            onPressed: _skipToNext,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            icon: Icons.skip_next_rounded,
            shadowColor: const Color(0xFF667EEA),
            label: 'NEXT',
          ),
          const SizedBox(width: 16),

          // Restart Button
          _buildControlButton(
            onPressed: _restartPlaylist,
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
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Refresh Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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

            // Top Header Bar with Now Playing
            if (_totalVideos > 0 && !_isLoading)
              _buildTopHeaderBar(),

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
    _presenter.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}