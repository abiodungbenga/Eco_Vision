import 'dart:io';
import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:vmodal_sdk_flutter/vmodal_sdk_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../../shared/models/search_result_model.dart';

/// What a collection can actually be searched for, read from the backend.
///
/// V-Modal creates one LanceDB table per indexed modality. Asking for a source
/// whose table was never created fails the WHOLE search with a 404, so the
/// request has to be built from what the backend reports rather than assumed.
class CollectionReadiness {
  const CollectionReadiness({
    required this.exists,
    required this.searchSources,
    required this.versionLancedb,
    required this.modalityTypes,
    required this.lancedbVersions,
    this.sourcesWereInferred = false,
  });

  /// Whether the collection was found for the current API key at all.
  final bool exists;

  /// Search sources to request, e.g. `['image']`.
  final List<String> searchSources;

  /// Latest `vN` index version, or null when the backend advertises none.
  /// Null is passed through to the search, which lets the backend pick its
  /// default — refusing to search would be worse than letting it answer.
  final int? versionLancedb;

  /// Raw backend modality names, kept for diagnostics.
  final List<String> modalityTypes;

  /// Raw backend `vN` strings, kept for diagnostics.
  final List<String> lancedbVersions;

  /// True when [searchSources] fell back to the modality this app submits
  /// because the backend advertised nothing recognizable.
  final bool sourcesWereInferred;

  /// Whether a search has any source to ask for. Diagnostic only — nothing
  /// gates on it.
  ///
  /// It deliberately ignores [versionLancedb]. An earlier version of this gate
  /// required a published version and was wired into [searchVideo], which
  /// blocked search indefinitely on collections that were in fact fully
  /// indexed. Search now attempts the call and reports the backend's own
  /// reason: a failed attempt gives a precise error, a refused one gives none.
  bool get isSearchable => exists && searchSources.isNotEmpty;

  /// True only when the backend itself advertises a queryable index: a
  /// recognized modality AND a published version.
  ///
  /// Stricter than [isSearchable] and used to decide when indexing has really
  /// landed, since the job status flips to `success` before the index is
  /// published.
  bool get isIndexPublished =>
      exists &&
      !sourcesWereInferred &&
      searchSources.isNotEmpty &&
      versionLancedb != null;

  /// Most recent versions to try, highest first, ending with `null` — the
  /// backend's own default.
  ///
  /// `createIndex` runs with the SDK's default `version: 'new_version'`, so
  /// every index job mints a NEW LanceDB version. The group listing can
  /// advertise that version before its table has been written, and asking for
  /// an unwritten table 404s the whole search. Walking down to older published
  /// versions turns that race into a slightly stale answer instead of a dead
  /// end. `null` is last: it targets the backend's `v0`, which is right only
  /// when nothing else is advertised.
  List<int?> get candidateVersions {
    final parsed = <int>{};
    for (final value in lancedbVersions) {
      // Same grammar as the SDK's own `latestLancedbVersion`.
      final match = RegExp(
        r'^v(\d+)$',
        caseSensitive: false,
      ).firstMatch(value.trim());
      final version = int.tryParse(match?.group(1) ?? '');
      if (version != null) parsed.add(version);
    }
    final ordered = parsed.toList()..sort((a, b) => b.compareTo(a));
    return <int?>[...ordered.take(maxVersionAttempts), null];
  }

  /// Cap on advertised versions tried before falling back to the default, so a
  /// collection with a long history cannot turn one search into many calls.
  static const int maxVersionAttempts = 3;
}

class VModalService extends GetxService {
  /// Separator VModal uses to build the backend group name from
  /// `projectId` + `collectionName`. Mirrors the SDK's internal
  /// `ContentScope`, which is deliberately not exported, so it cannot be
  /// imported and must be kept in sync by hand.
  static const String _backendSeparator = '__';

  /// Backend index modality -> the search source name it enables.
  /// Confirmed against the SDK's own fixture: `modality_types: ['vid_img_emb']`.
  static const Map<String, String> _modalityToSearchSource = <String, String>{
    'vid_img_emb': 'image',
    'vid_asr_txt': 'asr',
    'vid_ocr_txt': 'ocr',
  };

  /// Source matching the single modality [createIndex] submits.
  ///
  /// Read from the same constant the index job uses, so the two cannot drift.
  /// Used only as a fallback when the backend advertises no recognizable
  /// modality for a collection we know we indexed.
  static String? get _submittedSearchSource =>
      _modalityToSearchSource[AppConstants.defaultIndexType];

  final _isConfigured = false.obs;
  bool get isConfigured => _isConfigured.value;

  final _apiKey = ''.obs;
  String get apiKey => _apiKey.value;

  MutableApiKeyProvider? _apiKeyProvider;
  VModalProject? _project;
  VmodalClient? _client;

  String currentProjectId = AppConstants.defaultProjectId;
  String currentCollectionName = AppConstants.defaultCollectionName;
  String currentStreamName = AppConstants.defaultStreamName;

  /// Initializes V-Modal SDK with runtime API key.
  Future<bool> configure(String apiKey, {String? projectId}) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw VModalServiceException('API Key cannot be empty.');
    }

    try {
      // Clean previous resources
      await disposeResources();

      _apiKeyProvider = MutableApiKeyProvider(cleanKey);
      _client = VmodalClient(
        config: SdkConfig(apiKeyProvider: _apiKeyProvider!),
      );
      currentProjectId = (projectId != null && projectId.trim().isNotEmpty)
          ? projectId.trim()
          : AppConstants.defaultProjectId;

      _project = VModal.fromClient(
        projectId: currentProjectId,
        client: _client!,
      );

      _apiKey.value = cleanKey;
      _isConfigured.value = true;
      return true;
    } catch (e) {
      _isConfigured.value = false;
      throw VModalServiceException(
        'Failed to configure V-Modal SDK: ${e.toString()}',
      );
    }
  }

  /// Get active VModalScope for given collection and stream
  VModalScope getScope({String? collectionName, String? streamName}) {
    if (!_isConfigured.value || _project == null) {
      throw VModalServiceException(
        'V-Modal SDK is not configured. Please enter API key.',
      );
    }
    final col = (collectionName != null && collectionName.trim().isNotEmpty)
        ? collectionName.trim()
        : currentCollectionName;
    final stm = (streamName != null && streamName.trim().isNotEmpty)
        ? streamName.trim()
        : currentStreamName;

    return _project!.scope(collectionName: col, streamName: stm);
  }

  /// Lists available collections for the current project/API Key.
  Future<List<String>> listCollections() async {
    if (!_isConfigured.value || _project == null) {
      return [];
    }
    try {
      final collections = await _project!.listCollections(mode: 'vid_file');
      return collections;
    } catch (e) {
      // Return empty list on failure or error
      return [];
    }
  }

  /// Reads which modalities and index version a collection actually has.
  ///
  /// Call this before every search: a background indexing job can add a
  /// modality or publish a new version at any time.
  Future<CollectionReadiness> resolveReadiness({String? collectionName}) async {
    if (!_isConfigured.value || _client == null) {
      throw VModalServiceException('V-Modal SDK is not configured.');
    }

    final col = (collectionName != null && collectionName.trim().isNotEmpty)
        ? collectionName.trim()
        : currentCollectionName;
    final backendName = '$currentProjectId$_backendSeparator$col';

    try {
      final groups = await _client!.collections.listGroups(mode: 'vid_file');

      // Exact backend name first, then a suffix match so a change to the
      // SDK's encoding degrades into a miss rather than a wrong collection.
      var group = groups.findGroup(backendName, mode: 'vid_file');
      if (group == null) {
        final suffix = '$_backendSeparator$col';
        for (final candidate in groups.data) {
          if (candidate.groupName.trim().endsWith(suffix)) {
            group = candidate;
            break;
          }
        }
      }

      if (group == null) {
        developer.log(
          'Collection not found for this API key: backendName=$backendName, '
          'available=${groups.data.map((g) => g.groupName).toList()}',
          name: 'VModalService.readiness',
        );
        return const CollectionReadiness(
          exists: false,
          searchSources: <String>[],
          versionLancedb: null,
          modalityTypes: <String>[],
          lancedbVersions: <String>[],
        );
      }

      final sources = <String>[];
      for (final modality in group.modalityTypes) {
        final source = _modalityToSearchSource[modality.trim()];
        // Unknown modalities are skipped: requesting one 404s the search.
        if (source != null && !sources.contains(source)) sources.add(source);
      }

      // The group listing can advertise no usable modality even after a job
      // reported success — it is published asynchronously, and an upload-only
      // group reports just its raw modality. Falling back to the one modality
      // this app indexes keeps such a collection searchable; the alternative
      // was refusing to search a collection that actually works.
      var inferred = false;
      if (sources.isEmpty) {
        final fallback = _submittedSearchSource;
        if (fallback != null) {
          sources.add(fallback);
          inferred = true;
        }
      }

      final readiness = CollectionReadiness(
        exists: true,
        searchSources: sources,
        versionLancedb: group.latestLancedbVersion,
        modalityTypes: group.modalityTypes,
        lancedbVersions: group.lancedbVersions,
        sourcesWereInferred: inferred,
      );

      developer.log(
        'Readiness: collection=$col, backendName=$backendName, '
        'modalities=${group.modalityTypes}, sources=$sources, '
        'inferred=$inferred, versions=${group.lancedbVersions}, '
        'latest=${group.latestLancedbVersion}, '
        'searchable=${readiness.isSearchable}, '
        'published=${readiness.isIndexPublished}',
        name: 'VModalService.readiness',
      );
      // Full payload: the typed fields above lose any field the SDK does not
      // model, and those are what explain an unexpected verdict.
      developer.log(
        'Readiness raw group: ${group.raw}',
        name: 'VModalService.readiness',
      );
      return readiness;
    } catch (e) {
      throw SearchException(
        'Could not read index state for "$col": ${e.toString()}',
      );
    }
  }

  /// Uploads a video file to V-Modal signed storage.
  UploadTask<VideoUploadResponse> uploadVideo(
    File videoFile, {
    String? collectionName,
    String? streamName,
  }) {
    if (!_isConfigured.value) {
      throw VModalServiceException('V-Modal SDK is not configured.');
    }
    if (!videoFile.existsSync()) {
      throw VideoUploadException('Selected video file does not exist on disk.');
    }

    final scope = getScope(
      collectionName: collectionName,
      streamName: streamName,
    );

    return scope.upload(UploadSource.fromFile(videoFile));
  }

  /// Submits an indexation job for the uploaded video collection.
  Future<IndexationSubmitResponse> createIndex({
    String? collectionName,
    String? streamName,
  }) async {
    if (!_isConfigured.value) {
      throw VModalServiceException('V-Modal SDK is not configured.');
    }

    try {
      final scope = getScope(
        collectionName: collectionName,
        streamName: streamName,
      );

      final response = await scope.createIndex(
        options: const ScopedCreateIndexOptions(
          indexType: AppConstants.defaultIndexType,
          modality: AppConstants.defaultIndexType,
          // Kept on: each video now has its own stream, so this only ever
          // re-derives the one video, and it stops a retry after a partial
          // failure from skipping frames that were already claimed.
          reProcess: true,
        ),
      );
      return response;
    } catch (e) {
      throw IndexingException('Failed to submit indexing job: ${e.toString()}');
    }
  }

  /// Polls status of an indexing job.
  ///
  /// Takes the scope explicitly: the job was submitted against one video's
  /// stream, and defaulting to [currentStreamName] would poll a different one.
  Future<IndexationStatusResponse> checkIndexStatus(
    String jobId, {
    String? collectionName,
    String? streamName,
  }) async {
    if (!_isConfigured.value) {
      throw VModalServiceException('V-Modal SDK is not configured.');
    }
    if (jobId.trim().isEmpty) {
      throw IndexingException('Invalid job ID.');
    }

    try {
      final scope = getScope(
        collectionName: collectionName,
        streamName: streamName,
      );
      final response = await scope.indexStatus(jobId.trim());
      return response;
    } catch (e) {
      throw IndexingException('Failed to check index status: ${e.toString()}');
    }
  }

  /// Perform natural-language or visual semantic video search.
  ///
  /// Search sources are resolved from the backend rather than hardcoded:
  /// requesting a modality that was never indexed makes V-Modal 404 the entire
  /// request. The LanceDB version is retried from newest to oldest, because a
  /// freshly minted version can be advertised before its table exists.
  Future<SearchResponse> searchVideo({
    String? query,
    String? imageQuery,
    String? collectionName,
    String? streamName,
  }) async {
    if (!_isConfigured.value) {
      throw VModalServiceException('V-Modal SDK is not configured.');
    }

    final cleanQuery = query?.trim() ?? '';
    final hasImage = imageQuery != null && imageQuery.isNotEmpty;

    if (cleanQuery.isEmpty && !hasImage) {
      throw SearchException('Search query or reference image is required.');
    }

    final col = collectionName ?? currentCollectionName;
    final stm = streamName ?? currentStreamName;
    final readiness = await resolveReadiness(collectionName: collectionName);

    if (!readiness.exists) {
      throw SearchException(
        'Collection "$col" does not exist for this API key yet. '
        'Upload and index a video first.',
      );
    }

    // When searching by image, we specifically need the 'image' source to be available.
    if (hasImage && !readiness.searchSources.contains('image')) {
      throw SearchException(
        'Image search is not available for "$col". Make sure it was indexed with visual features.',
      );
    }

    if (readiness.searchSources.isEmpty) {
      throw SearchException(
        'No searchable modality is configured for "$col".',
      );
    }

    final scope = getScope(
      collectionName: collectionName,
      streamName: streamName,
    );
    return _searchInternal(
      scope: scope,
      query: cleanQuery,
      imageQuery: imageQuery,
      readiness: readiness,
      collectionName: col,
      streamName: stm,
    );
  }

  /// Searches the entire collection across all streams.
  Future<SearchResponse> searchCollection({
    String? query,
    String? imageQuery,
    String? collectionName,
  }) async {
    if (!_isConfigured.value) {
      throw VModalServiceException('V-Modal SDK is not configured.');
    }

    final col = collectionName ?? currentCollectionName;
    final readiness = await resolveReadiness(collectionName: collectionName);

    if (!readiness.exists) {
      throw SearchException('Collection "$col" does not exist.');
    }

    // We use the underlying client to search without a specific stream filter.
    // However, the SDK's SearchRequest defaults streamName to 'astream'.
    // We'll target the collection-level search if supported by the backend.
    final scope = getScope(collectionName: col, streamName: ''); 
    
    return _searchInternal(
      scope: scope,
      query: query?.trim() ?? '',
      imageQuery: imageQuery,
      readiness: readiness,
      collectionName: col,
      streamName: '',
    );
  }

  Future<SearchResponse> _searchInternal({
    required VModalScope scope,
    required String query,
    String? imageQuery,
    required CollectionReadiness readiness,
    required String collectionName,
    required String streamName,
  }) async {
    final hasImage = imageQuery != null && imageQuery.isNotEmpty;
    final attempts = readiness.candidateVersions;
    SearchException? missingTableFailure;

    for (var i = 0; i < attempts.length; i++) {
      final version = attempts[i];
      final isLastAttempt = i == attempts.length - 1;

      try {
        final response = await scope.search(
          query,
          options: ScopedSearchOptions(
            imageQuery: imageQuery,
            searchSources: hasImage ? ['image'] : readiness.searchSources,
            limit: 50,
            versionLancedb: version,
          ),
        );
        return response;
      } on ApiException catch (e) {
        final body = '${e.body}'.toLowerCase();
        final isMissingTable =
            body.contains('missing lancedb') || body.contains('missing index');

        if (!isMissingTable) {
          throw SearchException(
            'Search failed (${e.statusCode}): ${e.message}',
            code: '${e.statusCode}',
            details: e.body,
          );
        }

        missingTableFailure = SearchException(
          'Indexing may still be finishing — wait a moment and search again.',
          code: '${e.statusCode}',
          details: e.body,
        );
        if (isLastAttempt) throw missingTableFailure;
      } catch (e) {
        throw SearchException('Search request failed: ${e.toString()}');
      }
    }
    throw missingTableFailure ?? SearchException('Search failed.');
  }

  /// Resolves temporary image URLs for search results.
  Future<List<SearchResultModel>> resolveThumbnails(
    List<SearchResultModel> results, {
    String? collectionName,
  }) async {
    if (!_isConfigured.value || _client == null) return results;

    final col = collectionName ?? currentCollectionName;

    try {
      final records = results.map((r) {
        // Build the same record SearchResultModel.resolveTimestamps would build internally
        final timestamp = r.absoluteTimestampMs?.toString();
        return <String, Object?>{
          'mode': 'vid_file',
          'group_name': '$currentProjectId$_backendSeparator$col',
          'modality': 'vid_img',
          'stream_name': r.rawHit['stream_name'] ?? currentStreamName,
          'filename': r.videoFileName,
          'ts_unix_13digits': timestamp,
        };
      }).toList();

      final urlsResponse = await _client!.images.getUrlBulk(records);
      
      final updatedResults = <SearchResultModel>[];
      for (var i = 0; i < results.length; i++) {
        final row = urlsResponse.records[i];
        final url = '${row['url_pre_signed'] ?? ''}'.trim();
        updatedResults.add(results[i].copyWith(thumbnailUrl: url.isNotEmpty ? url : null));
      }
      return updatedResults;
    } catch (e) {
      developer.log('Thumbnail resolution failed: $e', name: 'VModalService');
      return results;
    }
  }

  /// Disposes active client and project resources safely.
  Future<void> disposeResources() async {
    try {
      _apiKeyProvider?.clear();
      _apiKeyProvider = null;
      if (_project != null) {
        await _project!.close();
        _project = null;
      }
      _client = null;
      _isConfigured.value = false;
      _apiKey.value = '';
    } catch (_) {}
  }

  @override
  void onClose() {
    disposeResources();
    super.onClose();
  }
}
