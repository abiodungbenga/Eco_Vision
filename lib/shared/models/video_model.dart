import '../../core/constants/app_constants.dart';

enum VideoStatus {
  idle,
  selected,
  uploading,
  indexing,
  indexed,
  error,
}

class VideoModel {
  final String id;
  final String fileName;
  final String filePath;
  final int sizeBytes;
  final VideoStatus status;
  final String? indexJobId;
  final String? errorMessage;
  final double uploadProgress;
  final String collectionName;

  /// Stream this video was uploaded to. Each video gets its own stream so a
  /// search never returns moments belonging to a different file. Built by
  /// `VideoService.buildStreamName`; the default is only a fallback for
  /// videos constructed without one.
  final String streamName;

  const VideoModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.sizeBytes,
    this.status = VideoStatus.idle,
    this.indexJobId,
    this.errorMessage,
    this.uploadProgress = 0.0,
    this.collectionName = AppConstants.defaultCollectionName,
    this.streamName = AppConstants.defaultStreamName,
  });

  bool get isIndexed => status == VideoStatus.indexed;
  bool get isUploading => status == VideoStatus.uploading;
  bool get isIndexing => status == VideoStatus.indexing;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  VideoModel copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? sizeBytes,
    VideoStatus? status,
    String? indexJobId,
    String? errorMessage,
    double? uploadProgress,
    String? collectionName,
    String? streamName,
  }) {
    return VideoModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      indexJobId: indexJobId ?? this.indexJobId,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      collectionName: collectionName ?? this.collectionName,
      streamName: streamName ?? this.streamName,
    );
  }
}
