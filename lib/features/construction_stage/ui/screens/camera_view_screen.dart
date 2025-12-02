import 'package:flutter/material.dart';
import 'package:mosstroinform_mobile/features/construction_stage/domain/entities/construction_site.dart';
import 'package:mosstroinform_mobile/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

/// Экран просмотра видеопотока камеры
class CameraViewScreen extends StatefulWidget {
  final Camera camera;

  const CameraViewScreen({super.key, required this.camera});

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (!widget.camera.isActive) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      // VideoPlayerController.networkUrl поддерживает потоковое видео:
      // - HLS потоки (.m3u8) - стандарт для потокового видео (поддерживается из коробки)
      // - DASH потоки
      // - Обычные видеофайлы через HTTP
      // Примечание: Для RTSP потоков может потребоваться дополнительный пакет
      // (например, flutter_vlc_player или media_kit)
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.camera.streamUrl),
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Для потокового видео не нужен looping, так как поток непрерывный
        _controller!.play();
        // setLooping не нужен для live streams
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка инициализации видео: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('URL потока: ${widget.camera.streamUrl}');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.camera.name)),
      body: _hasError
          ? _VideoErrorWidget(camera: widget.camera, l10n: l10n)
          : _isInitialized && _controller != null
          ? _VideoPlayerWidget(
              controller: _controller!,
              onPlayPause: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
            )
          : const _VideoLoadingWidget(),
    );
  }
}

/// Виджет видеоплеера
class _VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;

  const _VideoPlayerWidget({
    required this.controller,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Используем aspectRatio из контроллера, если он доступен, иначе 16/9 по умолчанию
    final aspectRatio = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : 16 / 9;
    
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            // Для потокового видео прогресс-бар показывает буферизацию
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing:
                    false, // Для live streams скроллинг не имеет смысла
                colors: VideoProgressColors(
                  playedColor: theme.colorScheme.primary,
                  bufferedColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              child: FloatingActionButton(
                onPressed: onPlayPause,
                child: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет загрузки видеопотока
class _VideoLoadingWidget extends StatelessWidget {
  const _VideoLoadingWidget();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.loadingVideoStream, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Виджет ошибки загрузки видеопотока
class _VideoErrorWidget extends StatelessWidget {
  final Camera camera;
  final AppLocalizations l10n;

  const _VideoErrorWidget({required this.camera, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            camera.isActive
                ? l10n.errorLoadingVideoStream
                : l10n.cameraNotActive,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (camera.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                camera.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
