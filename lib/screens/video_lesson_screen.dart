import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/progress_service.dart';

class VideoLessonScreen extends StatefulWidget {
  final String title;
  final String videoId;
  final String description;
  final List<String> keyPoints;
  final VoidCallback onVideoComplete;

  const VideoLessonScreen({
    Key? key,
    required this.title,
    required this.videoId,
    required this.description,
    required this.keyPoints,
    required this.onVideoComplete,
  }) : super(key: key);

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _videoCompleted = false;

  void _handleVideoComplete() {
    if (!_videoCompleted) {
      setState(() {
        _videoCompleted = true;
      });
      ProgressService.markVideoAsViewed(widget.title);
      widget.onVideoComplete();
    }
  }

  Future<void> _checkVideoProgress() async {
    final isViewed = await ProgressService.isVideoViewed(widget.title);
    if (isViewed) {
      setState(() {
        _videoCompleted = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkVideoProgress();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(
        title: Text(widget.title),
        actions: [
          if (_videoCompleted)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubePlayerBuilder(
            onEnterFullScreen: () {
              setState(() {
                _isFullScreen = true;
              });
            },
            onExitFullScreen: () {
              setState(() {
                _isFullScreen = false;
              });
            },
            player: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Theme.of(context).primaryColor,
              progressColors: ProgressBarColors(
                playedColor: Theme.of(context).primaryColor,
                handleColor: Theme.of(context).primaryColor,
              ),
              onEnded: (data) {
                _handleVideoComplete();
              },
            ),
            builder: (context, player) {
              return Column(
                children: [
                  player,
                  if (!_isFullScreen) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Key Points:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.keyPoints.map((point) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 20, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: !_videoCompleted
          ? FloatingActionButton.extended(
              onPressed: _handleVideoComplete,
              icon: const Icon(Icons.check),
              label: const Text('Mark as Completed'),
            )
          : null,
    );
  }
}
