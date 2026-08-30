import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_button.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/widgets/status_indicator.dart';
import '../controllers/upload_controller.dart';

class UploadView extends GetView<UploadController> {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Wildlife Footage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.video_collection_outlined,
                    color: Color(0xFF16A34A),
                    size: 28,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Select a wildlife or environmental video to upload to V-Modal for multimodal indexing.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF15803D),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Video File Selection Section
            Obx(() {
              final video = controller.currentVideo;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected File',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (video == null) ...[
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.folder_open_rounded,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No video selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Select Video',
                              icon: Icons.video_library_rounded,
                              onPressed: controller.isProcessing
                                  ? null
                                  : controller.selectVideo,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4D3E)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0xFF1B4D3E),
                              size: 26,
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${video.formattedSize} • ${video.collectionName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          StatusIndicator(status: video.status),
                          if (!controller.isProcessing)
                            TextButton.icon(
                              onPressed: () => _confirmReplace(context),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: Text(
                                video.status == VideoStatus.indexed
                                    ? 'Replace Video'
                                    : 'Change File',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Upload Progress & Index Status Card
            Obx(() {
              final video = controller.currentVideo;
              if (video == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload & Index Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress message banner
                    Text(
                      controller.statusMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Upload Progress bar
                    if (video.status == VideoStatus.uploading ||
                        controller.uploadProgress.value > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upload Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '${controller.uploadProgress.value.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: controller.uploadProgress.value / 100,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1B4D3E),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Index Job ID details
                    if (controller.jobId.value.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Job ID: ${controller.jobId.value.substring(0, controller.jobId.value.length > 12 ? 12 : controller.jobId.value.length)}...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Status: ${controller.indexStatus.value}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    if (controller.isProcessing) ...[
                      OutlinedButton.icon(
                        onPressed: controller.cancelUpload,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Cancel Processing',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ] else if (video.status == VideoStatus.indexed) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppButton(
                            label: 'Re-index Video',
                            icon: Icons.refresh_rounded,
                            isSecondary: true,
                            onPressed: controller.reindexCurrentVideo,
                          ),
                          AppButton(
                            label: 'Proceed to Search',
                            icon: Icons.search_rounded,
                            onPressed: controller.goToSearch,
                          ),
                        ],
                      ),
                    ] else if (video.status == VideoStatus.error) ...[
                      AppButton(
                        label: 'Try Indexing Again',
                        icon: Icons.refresh_rounded,
                        onPressed: controller.reindexCurrentVideo,
                      ),
                    ] else ...[
                      AppButton(
                        label: 'Upload & Index Video',
                        icon: Icons.cloud_upload_rounded,
                        isLoading: controller.isProcessing,
                        onPressed: controller.startUploadAndIndex,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReplace(BuildContext context) async {
    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace current video?'),
        content: const Text(
          'The current video will be removed from this app so you can select and index another one. The original file on your device will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Video'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (shouldReplace == true) {
      controller.removeCurrentVideo();
    }
  }
}
