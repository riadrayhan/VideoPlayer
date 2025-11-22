import 'package:flutter/material.dart';
import '../presenters/video_player_presenter.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> implements VideoPlayerView {
  final VideoPlayerPresenter _presenter = VideoPlayerPresenter();

  String _currentError = '';
  String _currentSuccess = '';
  bool _isLoading = true;
  int _currentVideoIndex = 0;
  int _totalVideos = 0;
  String _currentVideoName = '';
  Widget? _videoWidget;

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
        _currentSuccess = 'Initializing...';
      });
      await _presenter.init();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentError = 'Failed: $e';
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
      if (mounted && _currentError == message) setState(() => _currentError = '');
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
      if (mounted && _currentSuccess == message) setState(() => _currentSuccess = '');
    });
  }

  @override
  void updateVideo(Widget videoWidget) {
    if (!mounted) return;
    setState(() => _videoWidget = videoWidget);
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

  Future<void> _playVideo() async => _presenter.play();
  Future<void> _pauseVideo() async => _presenter.pause();
  Future<void> _skipToNext() async => _presenter.skipToNext();
  Future<void> _skipToPrevious() async => _presenter.skipToPrevious();
  Future<void> _restartPlaylist() async => _presenter.restartPlaylist();

  Future<void> _refreshSchedule() async {
    setState(() {
      _isLoading = true;
      _currentSuccess = 'Refreshing...';
    });
    await _presenter.refreshSchedule();
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildVideoPlayer() {
    if (_videoWidget != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(child: _videoWidget),
      );
    }
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(color: Colors.white70)),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white70, strokeWidth: 4),
            SizedBox(height: 32),
            Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 24)),
            SizedBox(height: 12),
            Text('Preparing playlist', style: TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.9), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 28),
            const SizedBox(width: 12),
            const Text("NOW PLAYING", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(child: Text(_currentVideoName, style: const TextStyle(color: Colors.white, fontSize: 15), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text("$_currentVideoIndex/$_totalVideos", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMessageOverlay() {
    return Positioned(
      bottom: 140, left: 24, right: 24,
      child: Column(
        children: [
          if (_currentError.isNotEmpty) _buildMessage(_currentError, Colors.redAccent),
          if (_currentSuccess.isNotEmpty) _buildMessage(_currentSuccess, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildMessage(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 30, left: 0, right: 0,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _btn(_skipToPrevious, Icons.skip_previous_rounded, Colors.purple),
        const SizedBox(width: 20),
        _btn(_playVideo, Icons.play_arrow_rounded, Colors.green),
        const SizedBox(width: 20),
        _btn(_pauseVideo, Icons.pause_rounded, Colors.orange),
        const SizedBox(width: 20),
        _btn(_skipToNext, Icons.skip_next_rounded, Colors.purple),
        const SizedBox(width: 20),
        _btn(_restartPlaylist, Icons.refresh_rounded, Colors.red),
      ]),
    );
  }

  Widget _btn(VoidCallback onPressed, IconData icon, Color color) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: color,
      onPressed: onPressed,
      child: Icon(icon, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isLoading ? _buildLoadingScreen() : _buildVideoPlayer(),
          if (_totalVideos > 0 && !_isLoading) _buildTopHeaderBar(),
          if (!_isLoading) _buildBottomMessageOverlay(),
          if (!_isLoading) _buildControlButtons(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }
}