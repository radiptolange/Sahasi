import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// --- VIDEO PLAYER WIDGET ---
// A simple video player dialog content.
class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  const VideoPlayerWidget({super.key, required this.videoPath});
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_initialized)
          AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
        else
          const CircularProgressIndicator(),
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context)
          )
        ),
        Positioned(
          bottom: 40,
          child: IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40
            ),
            onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play())
          )
        ),
      ],
    );
  }
}
