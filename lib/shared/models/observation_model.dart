class ObservationModel {
  final String id;
  final String species;
  final String videoId;
  final String videoName;
  final String videoPath;
  final int timestampMs;
  final String formattedTimestamp;
  final String searchQuery;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final String? notes;

  const ObservationModel({
    required this.id,
    required this.species,
    required this.videoId,
    required this.videoName,
    required this.videoPath,
    required this.timestampMs,
    required this.formattedTimestamp,
    required this.searchQuery,
    required this.createdAt,
    this.thumbnailUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'species': species,
      'videoId': videoId,
      'videoName': videoName,
      'videoPath': videoPath,
      'timestampMs': timestampMs,
      'formattedTimestamp': formattedTimestamp,
      'searchQuery': searchQuery,
      'createdAt': createdAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'notes': notes,
    };
  }

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    return ObservationModel(
      id: json['id'] ?? '',
      species: json['species'] ?? '',
      videoId: json['videoId'] ?? '',
      videoName: json['videoName'] ?? '',
      videoPath: json['videoPath'] ?? '',
      timestampMs: json['timestampMs'] ?? 0,
      formattedTimestamp: json['formattedTimestamp'] ?? '00:00',
      searchQuery: json['searchQuery'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      thumbnailUrl: json['thumbnailUrl'],
      notes: json['notes'],
    );
  }
}
