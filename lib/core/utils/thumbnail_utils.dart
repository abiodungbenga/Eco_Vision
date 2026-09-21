import 'package:video_snapshot_generator/video_snapshot_generator.dart';
import 'dart:developer' as developer;

class ThumbnailUtils {
  static Future<String?> generateVideoThumbnail({
    required String videoPath,
    int timeMs = 0,
    int width = 320,
    int height = 240,
    int quality = 75,
  }) async {
    try {
      final result = await VideoSnapshotGenerator.generateThumbnail(
        videoPath: videoPath,
        options: ThumbnailOptions(
          width: width,
          videoPath: videoPath,
          height: height,
          quality: quality,
          timeMs: timeMs,
          format: ThumbnailFormat.jpeg,
        ),
      );
      
      return result.path;
    } catch (e) {
      developer.log('Error generating thumbnail: $e', name: 'ThumbnailUtils');
      return null;
    }
  }
}
