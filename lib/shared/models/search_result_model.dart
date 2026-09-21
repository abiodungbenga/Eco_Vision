import '../../core/utils/duration_utils.dart';

/// Unit a timestamp key is documented to use, so a value like `45000` isn't
/// guessed at: `timestamp_ms` means 45s, `start_time` would mean 12.5 hours.
enum _TsUnit { seconds, millis, ambiguous }

/// A timestamp read off one hit, before it becomes an in-video offset.
class _TsReading {
  const _TsReading({this.relative, this.absoluteMs});

  /// Offset from the start of the video, when the backend gave us one directly.
  final Duration? relative;

  /// Absolute Unix epoch in ms, when that's all the backend gave us.
  final int? absoluteMs;
}

class SearchResultModel {
  final String id;
  final String query;
  final String title;
  final String description;
  final String formattedTimestamp;

  /// Offset to seek to inside the video.
  final Duration timestampDuration;
  final int timestampMs;

  /// Absolute Unix epoch in ms exactly as the backend reported it. This — not
  /// [timestampDuration] — is the frame key `VmodalClient.images.getUrl`
  /// expects, so keep it even though nothing reads it yet.
  final int? absoluteTimestampMs;

  /// True when [timestampDuration] was derived by subtracting a baseline
  /// guessed from the result set rather than read directly. See
  /// [resolveTimestamps] for why that guess is necessary and where it can drift.
  final bool isTimestampApproximate;

  /// False when the hit carried no usable timestamp at all, so the UI can say
  /// so instead of silently claiming 00:00.
  final bool hasTimestamp;

  final String scoreText;
  final String videoFileName;
  final String videoPath;
  final String? thumbnailUrl;
  final Map<String, dynamic> rawHit;

  const SearchResultModel({
    required this.id,
    required this.query,
    required this.title,
    required this.description,
    required this.formattedTimestamp,
    required this.timestampDuration,
    required this.timestampMs,
    required this.absoluteTimestampMs,
    required this.isTimestampApproximate,
    required this.hasTimestamp,
    required this.scoreText,
    required this.videoFileName,
    required this.videoPath,
    this.thumbnailUrl,
    required this.rawHit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'title': title,
      'description': description,
      'formattedTimestamp': formattedTimestamp,
      'timestampDurationMs': timestampDuration.inMilliseconds,
      'timestampMs': timestampMs,
      'absoluteTimestampMs': absoluteTimestampMs,
      'isTimestampApproximate': isTimestampApproximate,
      'hasTimestamp': hasTimestamp,
      'scoreText': scoreText,
      'videoFileName': videoFileName,
      'videoPath': videoPath,
      'thumbnailUrl': thumbnailUrl,
      'rawHit': rawHit,
    };
  }

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'],
      query: json['query'],
      title: json['title'],
      description: json['description'],
      formattedTimestamp: json['formattedTimestamp'],
      timestampDuration: Duration(milliseconds: json['timestampDurationMs']),
      timestampMs: json['timestampMs'],
      absoluteTimestampMs: json['absoluteTimestampMs'],
      isTimestampApproximate: json['isTimestampApproximate'],
      hasTimestamp: json['hasTimestamp'],
      scoreText: json['scoreText'],
      videoFileName: json['videoFileName'],
      videoPath: json['videoPath'],
      thumbnailUrl: json['thumbnailUrl'],
      rawHit: json['rawHit'],
    );
  }

  SearchResultModel copyWith({String? thumbnailUrl, String? videoPath}) {
    return SearchResultModel(
      id: id,
      query: query,
      title: title,
      description: description,
      formattedTimestamp: formattedTimestamp,
      timestampDuration: timestampDuration,
      timestampMs: timestampMs,
      absoluteTimestampMs: absoluteTimestampMs,
      isTimestampApproximate: isTimestampApproximate,
      hasTimestamp: hasTimestamp,
      scoreText: scoreText,
      videoFileName: videoFileName,
      videoPath: videoPath ?? this.videoPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rawHit: rawHit,
    );
  }

  /// Values at or above this are wall-clock epochs, not in-video offsets:
  /// 1e9 is 31 years as seconds and 11 days as milliseconds, and no clip is
  /// either.
  static const double _absoluteMin = 1e9;

  /// At or above this an absolute value is already in milliseconds; below it,
  /// it is in seconds.
  static const double _absoluteMinMillis = 1e12;

  /// Offsets from the start of the video. Preferred, because they need no
  /// baseline correction. First key present wins.
  static const Map<String, _TsUnit> _relativeKeys = <String, _TsUnit>{
    'start_time': _TsUnit.seconds,
    'timestamp_sec': _TsUnit.seconds,
    'time_offset': _TsUnit.seconds,
    'offset_sec': _TsUnit.seconds,
    'timestamp_ms': _TsUnit.millis,
    'timestamp': _TsUnit.ambiguous,
  };

  /// Absolute epoch keys, checked only when no relative key is usable.
  static const List<String> _absoluteKeys = <String>[
    'ts_unix_13digits',
    'ts_unix',
    'timestamp_ms',
    'timestamp',
  ];

  /// Last resort: an epoch key holding a value far too small to be a real
  /// epoch is malformed, and reading it as an offset beats discarding it.
  static const Map<String, _TsUnit> _epochKeysAsOffset = <String, _TsUnit>{
    'ts_unix_13digits': _TsUnit.millis,
    'ts_unix': _TsUnit.seconds,
  };

  /// Builds every result in one response together.
  ///
  /// This is batched rather than per-hit because V-Modal's frame rows carry
  /// `ts_unix_13digits` — an absolute Unix epoch in milliseconds, not an offset
  /// into the video. Seeking needs an offset, and neither `VideoUploadResponse`
  /// nor any SDK call reports the wall-clock time the video started, so the
  /// only available baseline is the earliest timestamp in the response.
  ///
  /// **This makes offsets approximate.** If no hit lands near the start of the
  /// video, every offset is shifted earlier by however far into the video the
  /// first hit actually is. Results tagged [isTimestampApproximate] came out of
  /// this path. Hits that report a relative key are exact and are preferred.
  ///
  /// Subtracting a shared baseline is only sound because all hits in a response
  /// belong to one video — which holds now that each video gets its own stream.
  static List<SearchResultModel> resolveTimestamps(
    List<Map<String, dynamic>> hits, {
    required String query,
    required String videoPath,
  }) {
    final readings = hits.map(_readTimestamp).toList(growable: false);

    final baselines = <String, int>{};
    for (var i = 0; i < hits.length; i++) {
      final map = hits[i];
      final videoName = _extractFirstText(map, [
        'filename',
        'filename_sanitized',
        'video_filename',
        'video',
        'source_path',
        'path',
      ]);
      final absolute = readings[i].absoluteMs;
      if (absolute == null) continue;
      final currentBaseline = baselines[videoName];
      if (currentBaseline == null || absolute < currentBaseline) {
        baselines[videoName] = absolute;
      }
    }

    final results = <SearchResultModel>[];
    for (var i = 0; i < hits.length; i++) {
      final map = hits[i];
      final videoName = _extractFirstText(map, [
        'filename',
        'filename_sanitized',
        'video_filename',
        'video',
        'source_path',
        'path',
      ]);
      final baselineMs = baselines[videoName];
      results.add(
        _fromHit(
          map,
          reading: readings[i],
          baselineMs: baselineMs,
          query: query,
          videoPath: videoPath,
        ),
      );
    }
    return results;
  }

  static SearchResultModel _fromHit(
    Map<String, dynamic> map, {
    required _TsReading reading,
    required int? baselineMs,
    required String query,
    required String videoPath,
  }) {
    final title = _extractFirstText(map, [
      'title',
      'effective_title',
      'caption',
      'description',
      'text',
      'ocr',
      'asr',
      'item_id',
    ]);

    final videoName = _extractFirstText(map, [
      'filename',
      'filename_sanitized',
      'video_filename',
      'video',
      'source_path',
      'path',
    ]);

    var duration = Duration.zero;
    var approximate = false;
    var resolved = false;

    final relative = reading.relative;
    final absolute = reading.absoluteMs;
    if (relative != null) {
      duration = relative;
      resolved = true;
    } else if (absolute != null && baselineMs != null) {
      duration = Duration(milliseconds: absolute - baselineMs);
      if (duration.isNegative) duration = Duration.zero;
      approximate = true;
      resolved = true;
    }

    final formattedTs = DurationUtils.formatDuration(duration);
    final scoreStr = _extractScore(map);

    final idStr =
        map['id']?.toString() ??
        map['item_id']?.toString() ??
        'hit_${duration.inMilliseconds}_${DateTime.now().microsecondsSinceEpoch}';

    return SearchResultModel(
      id: idStr,
      query: query,
      title: title.isNotEmpty ? title : 'Wildlife Moment ($formattedTs)',
      description:
          map['description']?.toString() ??
          map['ocr']?.toString() ??
          map['asr']?.toString() ??
          '',
      formattedTimestamp: resolved ? formattedTs : '--:--',
      timestampDuration: duration,
      timestampMs: duration.inMilliseconds,
      absoluteTimestampMs: absolute,
      isTimestampApproximate: approximate,
      hasTimestamp: resolved,
      scoreText: scoreStr,
      videoFileName: videoName,
      videoPath: videoPath,
      rawHit: map,
    );
  }

  static _TsReading _readTimestamp(Map<String, dynamic> row) {
    for (final entry in _relativeKeys.entries) {
      final offset = _relativeFrom(row[entry.key], entry.value);
      if (offset != null) return _TsReading(relative: offset);
    }

    for (final key in _absoluteKeys) {
      final absolute = _absoluteMsFrom(row[key]);
      if (absolute != null) return _TsReading(absoluteMs: absolute);
    }

    for (final entry in _epochKeysAsOffset.entries) {
      final offset = _relativeFrom(row[entry.key], entry.value);
      if (offset != null) return _TsReading(relative: offset);
    }

    return const _TsReading();
  }

  static Duration? _relativeFrom(dynamic value, _TsUnit unit) {
    if (value == null) return null;

    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value'.trim());

    if (number == null) {
      // Only clock strings like "01:23" land here, and those are always
      // in-video offsets.
      final parsed = DurationUtils.parseTimestampToDuration(value);
      return parsed > Duration.zero ? parsed : null;
    }

    if (!number.isFinite || number <= 0) return null;
    // A wall-clock epoch, so not a usable offset — handled by _absoluteMsFrom.
    if (number >= _absoluteMin) return null;

    switch (unit) {
      case _TsUnit.seconds:
        return Duration(milliseconds: (number * 1000).round());
      case _TsUnit.millis:
        return Duration(milliseconds: number.round());
      case _TsUnit.ambiguous:
        return DurationUtils.parseTimestampToDuration(value);
    }
  }

  static int? _absoluteMsFrom(dynamic value) {
    if (value == null) return null;

    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value'.trim());

    if (number == null || !number.isFinite || number < _absoluteMin) return null;
    return number >= _absoluteMinMillis
        ? number.round()
        : (number * 1000).round();
  }

  static String _extractFirstText(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = '${row[key] ?? ''}'.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _extractScore(Map<String, dynamic> row) {
    final scoreUi = row['score_ui'];
    if (scoreUi is num && scoreUi.isFinite && scoreUi >= 0 && scoreUi <= 1) {
      return '${(scoreUi * 100).toStringAsFixed(1)}%';
    }

    for (final key in [
      'score_ui',
      'score',
      'similarity',
      'image_score',
      'text_score',
    ]) {
      final val = row[key];
      if (val is num && val.isFinite) {
        if (val >= 0 && val <= 1) {
          return '${(val * 100).toStringAsFixed(1)}%';
        }
        return val.toStringAsFixed(2);
      }
      final s = '${val ?? ''}'.trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}
