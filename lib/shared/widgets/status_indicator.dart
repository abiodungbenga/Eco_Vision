import 'package:flutter/material.dart';
import '../models/video_model.dart';

class StatusIndicator extends StatelessWidget {
  final VideoStatus status;
  final String? customText;

  const StatusIndicator({
    super.key,
    required this.status,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
              ),
            )
          else
            Icon(config.icon, size: 14, color: config.textColor),
          const SizedBox(width: 6),
          Text(
            customText ?? config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig() {
    switch (status) {
      case VideoStatus.idle:
        return _StatusConfig(
          label: 'Idle',
          icon: Icons.hourglass_empty_rounded,
          backgroundColor: const Color(0xFFF7FAFC),
          borderColor: const Color(0xFFE2E8F0),
          textColor: const Color(0xFF718096),
        );
      case VideoStatus.selected:
        return _StatusConfig(
          label: 'Ready to Upload',
          icon: Icons.file_present_rounded,
          backgroundColor: const Color(0xFFEBF8FF),
          borderColor: const Color(0xFFBEE3F8),
          textColor: const Color(0xFF2B6CB0),
        );
      case VideoStatus.uploading:
        return _StatusConfig(
          label: 'Uploading...',
          icon: Icons.cloud_upload_outlined,
          isLoading: true,
          backgroundColor: const Color(0xFFFEFCBF),
          borderColor: const Color(0xFFFAF089),
          textColor: const Color(0xFFB7791F),
        );
      case VideoStatus.indexing:
        return _StatusConfig(
          label: 'Indexing Video...',
          icon: Icons.sync_rounded,
          isLoading: true,
          backgroundColor: const Color(0xFFEBF8FF),
          borderColor: const Color(0xFF90CDF4),
          textColor: const Color(0xFF2C5282),
        );
      case VideoStatus.indexed:
        return _StatusConfig(
          label: 'Ready to Search',
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: const Color(0xFFC6F6D5),
          borderColor: const Color(0xFF9AE6B4),
          textColor: const Color(0xFF22543D),
        );
      case VideoStatus.error:
        return _StatusConfig(
          label: 'Failed',
          icon: Icons.error_outline_rounded,
          backgroundColor: const Color(0xFFFED7D7),
          borderColor: const Color(0xFFFEB2B2),
          textColor: const Color(0xFF9B2C2C),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool isLoading;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.isLoading = false,
  });
}
