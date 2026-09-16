import 'package:flutter/material.dart';
import '../models/video_model.dart';
import 'status_indicator.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onTap;
  final VoidCallback? onUploadTap;
  final VoidCallback? onSearchTap;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.onUploadTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.video_file_rounded,
                    color: Color(0xFF1B4D3E),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${video.formattedSize} • Collection: ${video.collectionName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusIndicator(status: video.status),
                if (video.status == VideoStatus.indexed && onSearchTap != null)
                  ElevatedButton.icon(
                    onPressed: onSearchTap,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else if (video.status == VideoStatus.selected && onUploadTap != null)
                  ElevatedButton.icon(
                    onPressed: onUploadTap,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Upload & Index'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B6CB0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
            if (video.isUploading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: video.uploadProgress / 100,
                  backgroundColor: const Color(0xFFEDF2F7),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
