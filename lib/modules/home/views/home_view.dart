import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/widgets/video_card.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco_rounded, color: Color(0xFF1B4D3E), size: 24),
            SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'API Key Configuration',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Environmental Video Research',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Index wildlife footage and search moments using natural language powered by V-Modal AI.',
                    style: TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SDK Configuration Status Widget
            Obx(() {
              final isConfigured = controller.vmodalService.isConfigured;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isConfigured
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConfigured
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConfigured
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: isConfigured
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConfigured
                            ? 'V-Modal SDK active & authenticated'
                            : 'V-Modal API key needed to enable live search',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isConfigured
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showApiKeyDialog(context),
                      child: Text(isConfigured ? 'Change' : 'Set Key'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Quick Actions Section
            LayoutBuilder(
              builder: (context, constraints) {
                final uploadButton = AppButton(
                  label: 'Upload Video',
                  icon: Icons.video_call_rounded,
                  onPressed: controller.goToUpload,
                );
                final searchButton = AppButton(
                  label: 'Search Footage',
                  icon: Icons.search_rounded,
                  isSecondary: true,
                  onPressed: controller.goToSearch,
                );

                if (constraints.maxWidth < 400) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      uploadButton,
                      const SizedBox(height: 10),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: uploadButton),
                    const SizedBox(width: 14),
                    Expanded(child: searchButton),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Active Video Section
            const Text(
              'Current Wildlife Footage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final video = controller.currentVideo;
              if (video == null) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 42,
                        color: Color(0xFFA0AEC0),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No footage uploaded yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select a wildlife video to upload and index using V-Modal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: controller.goToUpload,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Select Wildlife Footage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return VideoCard(
                video: video,
                onUploadTap: controller.goToUpload,
                onSearchTap: controller.goToSearch,
              );
            }),
            const SizedBox(height: 28),

            // Research Guide Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: Color(0xFF475569),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'How EcoVision Works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Select environmental video footage from your device.\n'
                    '2. Upload & index it with V-Modal multimodal engine.\n'
                    '3. Query moments in natural language ("elephants near water").\n'
                    '4. Jump directly to matching video timestamps.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('V-Modal API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your V-Modal runtime API key to authorize indexing and search:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller.apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter API Key',
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.saveApiKey(controller.apiKeyController.text);
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }
}
