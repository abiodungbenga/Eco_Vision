import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/widgets/error_state.dart';
import '../controllers/player_controller.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.videoName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (controller.resultTitle.isNotEmpty)
              Text(
                'Moment: "${controller.resultTitle}" @ ${controller.targetTimestampText}',
                style: const TextStyle(
                  color: Color(0xFF81C784),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: ErrorState(
                title: 'Player Error',
                message: controller.errorMessage.value,
              ),
            ),
          );
        }

        if (!controller.isInitialized.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading video footage & seeking to moment...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final vpc = controller.videoPlayerController!;

        return SafeArea(
          child: Column(
            children: [
              // Main Video Display Container
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: vpc.value.aspectRatio > 0 ? vpc.value.aspectRatio : 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(vpc),

                        if (controller.isBuffering.value)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),

                        // Tap overlay to play/pause
                        GestureDetector(
                          onTap: controller.togglePlayPause,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedOpacity(
                            opacity: controller.isPlaying.value ? 0.0 : 0.8,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              color: Colors.black45,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    controller.isPlaying.value
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 54,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Playback Controls Bar
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Explains any gap between the advertised moment and where
                    // playback actually started.
                    Obx(() {
                      final notice = controller.seekNotice.value;
                      if (notice.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Color(0xFFFCD34D),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                notice,
                                style: const TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Position Slider
                    Obx(() {
                      final pos = controller.currentPosition.value.inMilliseconds.toDouble();
                      final total = controller.totalDuration.value.inMilliseconds.toDouble();
                      final maxVal = total > 0 ? total : 1.0;
                      final currVal = pos.clamp(0.0, maxVal);

                      return SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFF81C784),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFF81C784),
                        ),
                        child: Slider(
                          value: currVal,
                          min: 0.0,
                          max: maxVal,
                          onChanged: (val) {
                            controller.seekTo(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      );
                    }),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Play/Pause button and timestamp readout
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                controller.isPlaying.value
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                              onPressed: controller.togglePlayPause,
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final posStr = DurationUtils.formatDuration(controller.currentPosition.value);
                              final durStr = DurationUtils.formatDuration(controller.totalDuration.value);
                              return Text(
                                '$posStr / $durStr',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              );
                            }),
                          ],
                        ),

                        // Jump to moment badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4D3E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bookmark_rounded, size: 14, color: Color(0xFF81C784)),
                              const SizedBox(width: 4),
                              Text(
                                'Moment: ${controller.targetTimestampText}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
            ],
          ),
        );
      }),
    );
  }
}
