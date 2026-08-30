class WildlifeSearchResult {
  final String id;
  final String videoId;
  final String title;
  final String description;
  final Duration startTime;
  final Duration endTime;
  final double score;
  final String? thumbnailUrl;
  final String videoUrl;

  const WildlifeSearchResult({
    required this.id,
    required this.videoId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.score,
    this.thumbnailUrl,
    required this.videoUrl,
  });

  String get timeRange => '${_formatDuration(startTime)} — ${_formatDuration(endTime)}';
  String get relevancePercentage => '${(score * 100).toStringAsFixed(0)}%';

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
