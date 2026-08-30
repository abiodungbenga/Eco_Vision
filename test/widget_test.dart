import 'package:flutter_test/flutter_test.dart';
import 'package:wild_sense/app/app.dart';
import 'package:wild_sense/core/services/video_service.dart';
import 'package:wild_sense/core/services/vmodal_service.dart';
import 'package:wild_sense/core/utils/duration_utils.dart';
import 'package:wild_sense/shared/models/search_result_model.dart';

void main() {
  testWidgets('EcoVision app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoVisionApp());
    expect(find.text('EcoVision'), findsOneWidget);
  });

  group('DurationUtils tests', () {
    test('formatDuration formats MM:SS and HH:MM:SS correctly', () {
      expect(DurationUtils.formatDuration(const Duration(seconds: 14)), '00:14');
      expect(DurationUtils.formatDuration(const Duration(minutes: 2, seconds: 37)), '02:37');
      expect(DurationUtils.formatDuration(const Duration(hours: 1, minutes: 5, seconds: 9)), '01:05:09');
    });

    test('parseTimestampToDuration parses seconds, milliseconds and clock strings', () {
      // The bare-number path is unit-ambiguous: it reads values over 100000 as
      // milliseconds and anything smaller as seconds. It cannot do better
      // without knowing which key the value came from, which is why
      // SearchResultModel resolves units per key and only falls back to here
      // for clock strings and genuinely ambiguous keys.
      expect(DurationUtils.parseTimestampToDuration(14).inSeconds, 14);
      expect(DurationUtils.parseTimestampToDuration(14.0).inSeconds, 14);
      expect(DurationUtils.parseTimestampToDuration(150000).inSeconds, 150);
      expect(DurationUtils.parseTimestampToDuration('02:37').inSeconds, 157);
      expect(DurationUtils.parseTimestampToDuration('01:05:09').inSeconds, 3909);
      expect(DurationUtils.parseTimestampToDuration(null), Duration.zero);
    });
  });

  group('SearchResultModel tests', () {
    test('resolveTimestamps parses a V-Modal search response hit map', () {
      final hitMap = {
        'title': 'Elephant walking near water',
        'filename': 'wildlife_footage.mp4',
        'ts_unix_13digits': 14000,
        'score_ui': 0.94,
        'description': 'Elephant observed near river edge',
      };

      final result = SearchResultModel.resolveTimestamps(
        [hitMap],
        query: 'elephants near water',
        videoPath: '/path/to/video.mp4',
      ).single;

      expect(result.title, 'Elephant walking near water');
      expect(result.formattedTimestamp, '00:14');
      expect(result.timestampDuration.inSeconds, 14);
      expect(result.scoreText, '94.0%');
      expect(result.videoFileName, 'wildlife_footage.mp4');
    });

    test('absolute epoch timestamps become offsets from the earliest hit', () {
      // What the backend really sends: ts_unix_13digits is wall-clock ms, not
      // an in-video offset. Seeking to it directly overshot by ~54 years, so
      // the player skipped the seek and every moment played from 00:00.
      const base = 1700000000000;
      final hits = [
        {'title': 'first', 'ts_unix_13digits': base},
        {'title': 'later', 'ts_unix_13digits': base + 12000},
        {'title': 'latest', 'ts_unix_13digits': base + 65500},
      ];

      final results = SearchResultModel.resolveTimestamps(
        hits,
        query: 'bear',
        videoPath: '/path/to/video.mp4',
      );

      expect(results.map((r) => r.formattedTimestamp).toList(), [
        '00:00',
        '00:12',
        '01:05',
      ]);
      expect(results.every((r) => r.isTimestampApproximate), isTrue);
      expect(results.every((r) => r.hasTimestamp), isTrue);
      // The raw epoch is preserved: images.getUrl needs exactly this value.
      expect(results[1].absoluteTimestampMs, base + 12000);
    });

    test('relative keys win over absolute ones and stay exact', () {
      final results = SearchResultModel.resolveTimestamps(
        [
          {'title': 'hit', 'start_time': 42.5, 'ts_unix_13digits': 1700000000000},
        ],
        query: 'bear',
        videoPath: '/path/to/video.mp4',
      );

      expect(results.single.timestampDuration.inMilliseconds, 42500);
      expect(results.single.isTimestampApproximate, isFalse);
    });

    test('a hit with no timestamp is flagged instead of claiming 00:00', () {
      final results = SearchResultModel.resolveTimestamps(
        [
          {'title': 'hit', 'score_ui': 0.8},
        ],
        query: 'bear',
        videoPath: '/path/to/video.mp4',
      );

      expect(results.single.hasTimestamp, isFalse);
      expect(results.single.formattedTimestamp, '--:--');
      expect(results.single.timestampDuration, Duration.zero);
    });
  });

  group('CollectionReadiness tests', () {
    CollectionReadiness readiness({
      List<String> versions = const <String>[],
      List<String> modalities = const <String>['vid_img_emb'],
      bool inferred = false,
    }) {
      return CollectionReadiness(
        exists: true,
        searchSources: const <String>['image'],
        versionLancedb: null,
        modalityTypes: modalities,
        lancedbVersions: versions,
        sourcesWereInferred: inferred,
      );
    }

    test('candidateVersions walks newest to oldest, then the default', () {
      // createIndex defaults to version: 'new_version', so every index run
      // mints a new version. The newest can be advertised before its table is
      // written, and asking for an unwritten table 404s the whole search.
      final versions = readiness(
        versions: const <String>['v0', 'v2', 'V10', 'v3', 'invalid'],
      ).candidateVersions;

      expect(versions, <int?>[10, 3, 2, null]);
    });

    test('candidateVersions is just the default when none are advertised', () {
      expect(readiness().candidateVersions, <int?>[null]);
    });

    test('candidateVersions dedupes and caps the walk', () {
      final versions = readiness(
        versions: const <String>['v1', 'v1', 'v2', 'v3', 'v4', 'v5'],
      ).candidateVersions;

      expect(versions.length, CollectionReadiness.maxVersionAttempts + 1);
      expect(versions, <int?>[5, 4, 3, null]);
    });

    test('isSearchable does not depend on an advertised version', () {
      // This is the regression that mattered: gating search on a nullable
      // version refused to search collections that were in fact indexed.
      expect(readiness().versionLancedb, isNull);
      expect(readiness().isSearchable, isTrue);
    });

    test('isIndexPublished requires a real version and real modality', () {
      expect(readiness().isIndexPublished, isFalse);

      final published = CollectionReadiness(
        exists: true,
        searchSources: const <String>['image'],
        versionLancedb: 2,
        modalityTypes: const <String>['vid_img_emb'],
        lancedbVersions: const <String>['v2'],
      );
      expect(published.isIndexPublished, isTrue);

      // An inferred source is a guess, so it must not confirm publication.
      expect(readiness(inferred: true).isIndexPublished, isFalse);
    });
  });

  group('VideoService.buildStreamName tests', () {
    test('sanitizes to the characters V-Modal accepts', () {
      // ContentScope._normalize rejects anything outside [A-Za-z0-9_].
      final name = VideoService.buildStreamName('bear video.mp4', '1699999999');
      expect(name, matches(RegExp(r'^[A-Za-z0-9_]+$')));
      expect(name, 'vid_bear_video_mp4_1699999999');
    });

    test('stays within the 80 character limit', () {
      final name = VideoService.buildStreamName('${'a' * 200}.mp4', '1699999999');
      expect(name.length, lessThanOrEqualTo(80));
      expect(name, endsWith('_1699999999'));
    });

    test('falls back when the file name sanitizes to nothing', () {
      expect(VideoService.buildStreamName('...', '42'), 'vid_42');
    });
  });
}
