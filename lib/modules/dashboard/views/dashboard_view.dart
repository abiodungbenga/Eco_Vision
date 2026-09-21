import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../shared/models/observation_model.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Good morning / afternoon',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Environmental Research Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),

            // Statistics Grid (Responsive layouts)
            Obx(() => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard('${controller.videosAnalyzed.value}', 'Videos analyzed', Icons.video_library_rounded, const Color(0xFFEBF8FF), const Color(0xFF2B6CB0)),
                    _buildStatCard('${controller.observationCount.value}', 'Observations saved', Icons.science_rounded, const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
                    _buildStatCard('${controller.speciesCount.value}', 'Species detected', Icons.pets_rounded, const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
                    _buildStatCard('${controller.monthlySearchCount.value}', 'Searches this month', Icons.search_rounded, const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                  ],
                )),
            const SizedBox(height: 24),

            // Most Observed Species Section
            const Text(
              'Most Observed Species',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.mostObservedSpecies.isEmpty) {
                return _buildEmptySection('No species data recorded yet.');
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.mostObservedSpecies.take(4).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sp = controller.mostObservedSpecies[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.pets_rounded, color: Color(0xFF1B4D3E), size: 18),
                      title: Text(sp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: Text('${sp.observationCount} sightings', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 24),

            // Recent Observations Section
            const Text(
              'Recent Observations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.recentObservations.isEmpty) {
                return _buildEmptySection('No recent observations saved.');
              }
              return Column(
                children: controller.recentObservations.map((obs) => _buildRecentObservationTile(obs)).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String val, String title, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildRecentObservationTile(ObservationModel obs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        title: Text(obs.species, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B4D3E))),
        subtitle: Text('${obs.videoName} @ ${obs.formattedTimestamp}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatTimeAgo(obs.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0))),
            const SizedBox(width: 6),
            const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF1B4D3E), size: 22),
          ],
        ),
        onTap: () => controller.watchObservation(obs),
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ),
    );
  }
}
