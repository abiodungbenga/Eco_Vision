import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../shared/models/species_model.dart';
import '../controllers/observations_controller.dart';

class ObservationDetailView extends StatelessWidget {
  final SpeciesModel species;

  const ObservationDetailView({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ObservationsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(species.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('${species.observationCount}', 'Observations'),
                _buildStatItem('${species.videoCount}', 'Videos'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recent Saved Moments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: species.observations.length,
              itemBuilder: (context, index) {
                final obs = species.observations[index];
                return Card(
                  margin: const EdgeInsets.bottom(12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail or placeholder
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (obs.thumbnailUrl != null && obs.thumbnailUrl!.isNotEmpty)
                              ? (obs.thumbnailUrl!.startsWith('http')
                                  ? Image.network(obs.thumbnailUrl!, fit: BoxFit.cover)
                                  : Image.file(File(obs.thumbnailUrl!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20)))
                              : const Icon(Icons.video_file_rounded, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                obs.videoName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Timestamp: ${obs.formattedTimestamp}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B4D3E)),
                              ),
                              if (obs.searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Query: "${obs.searchQuery}"',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF1B4D3E), size: 32),
                          onPressed: () => controller.watchObservation(obs),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
