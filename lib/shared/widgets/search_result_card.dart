import 'package:flutter/material.dart';
import 'dart:io';

import 'package:get/get.dart';
import '../models/search_result_model.dart';
import '../models/observation_model.dart';
import '../../core/services/discovery_service.dart';
import '../../core/services/research_service.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResultModel result;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  Widget _buildThumbnail() {
    final url = result.thumbnailUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Color(0xFFA0AEC0),
          size: 24,
        ),
      );
    }

    final isLocal = !url.startsWith('http') && !url.startsWith('https');

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: isLocal
          ? Image.file(
              File(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, size: 20),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, size: 20),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoveryService = Get.find<DiscoveryService>();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail & Timestamp stack
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildThumbnail(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result.isTimestampApproximate
                          ? '~${result.formattedTimestamp}'
                          : result.formattedTimestamp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title and metadata details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF718096),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (result.scoreText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBEE3F8),
                              ),
                            ),
                            child: Text(
                              'Match: ${result.scoreText}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B6CB0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            result.videoFileName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA0AEC0),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.science_rounded, size: 14),
                      label: const Text('Save Observation', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4D3E),
                        side: const BorderSide(color: Color(0xFF1B4D3E)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showSaveObservationDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              
              // Bookmark and Arrow
              Column(
                children: [
                  Obx(() => IconButton(
                        icon: Icon(
                          discoveryService.isBookmarked(result)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: const Color(0xFF1B4D3E),
                          size: 20,
                        ),
                        onPressed: () => discoveryService.toggleBookmark(result),
                      )),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveObservationDialog(BuildContext context) {
    String guessedSpecies = 'Wildlife';
    final queryLower = result.query.toLowerCase();
    if (queryLower.contains('elephant')) guessedSpecies = 'Elephant';
    else if (queryLower.contains('bird')) guessedSpecies = 'Bird';
    else if (queryLower.contains('lion')) guessedSpecies = 'Lion';
    else if (queryLower.contains('antelope')) guessedSpecies = 'Antelope';
    else if (queryLower.contains('bear')) guessedSpecies = 'Bear';
    else if (queryLower.contains('human') || queryLower.contains('people')) guessedSpecies = 'Human';
    else if (result.query.isNotEmpty) {
      guessedSpecies = result.query.split(' ').first.capitalizeFirst ?? result.query;
    }

    final controller = TextEditingController(text: guessedSpecies);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Research Observation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the species name or category for this observation:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Species / Category',
                hintText: 'e.g. Elephant, Bird, Lion',
              ),
            ),
            const SizedBox(height: 12),
            Text('Video: ${result.videoFileName}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Text('Timestamp: ${result.formattedTimestamp}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
            onPressed: () async {
              final speciesName = controller.text.trim();
              if (speciesName.isEmpty) {
                return;
              }
              Navigator.pop(context);

              final researchService = Get.find<ResearchService>();
              final obs = ObservationModel(
                id: 'obs_${DateTime.now().millisecondsSinceEpoch}',
                species: speciesName,
                videoId: result.id,
                videoName: result.videoFileName,
                videoPath: result.videoPath,
                timestampMs: result.timestampMs,
                formattedTimestamp: result.formattedTimestamp,
                searchQuery: result.query,
                createdAt: DateTime.now(),
                thumbnailUrl: result.thumbnailUrl,
              );

              final success = await researchService.saveObservation(obs);
              if (success) {
                Get.snackbar(
                  'Success',
                  'Observation saved under $speciesName',
                  backgroundColor: const Color(0xFFF0FDF4),
                  colorText: const Color(0xFF15803D),
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Info',
                  'This observation is already saved.',
                  backgroundColor: const Color(0xFFFFFBEB),
                  colorText: const Color(0xFFB45309),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
