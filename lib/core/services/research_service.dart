import 'package:get/get.dart';
import 'package:localstore/localstore.dart';
import '../../shared/models/observation_model.dart';
import '../../shared/models/species_model.dart';

class ResearchService extends GetxService {
  final _db = Localstore.instance;
  static const String _obsCollection = 'research_observations';
  static const String _searchCollection = 'search_history';

  final observations = <ObservationModel>[].obs;
  final searchHistory = <Map<String, dynamic>>[].obs; // contains 'query' and 'timestamp'

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      // Load observations
      final obsItems = await _db.collection(_obsCollection).get();
      if (obsItems != null) {
        final loadedObs = obsItems.entries
            .map((e) => ObservationModel.fromJson(e.value))
            .toList();
        // Sort newest first
        loadedObs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        observations.assignAll(loadedObs);
      }

      // Load search history
      final searchItems = await _db.collection(_searchCollection).get();
      if (searchItems != null) {
        final loadedSearches = searchItems.entries
            .map((e) => Map<String, dynamic>.from(e.value))
            .toList();
        // Sort newest first
        loadedSearches.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
        searchHistory.assignAll(loadedSearches);
      }
    } catch (_) {
      // Fail gracefully
    }
  }

  Future<bool> saveObservation(ObservationModel obs) async {
    // Prevent exact duplicate based on species, videoName, and timestampMs
    final exists = observations.any((o) =>
        o.species.toLowerCase() == obs.species.toLowerCase() &&
        o.videoName == obs.videoName &&
        (o.timestampMs - obs.timestampMs).abs() < 1000);

    if (exists) {
      return false; // Already exists
    }

    try {
      await _db.collection(_obsCollection).doc(obs.id).set(obs.toJson());
      observations.insert(0, obs);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now().toIso8601String();
    final searchData = {
      'id': id,
      'query': query.trim(),
      'timestamp': timestamp,
    };

    try {
      await _db.collection(_searchCollection).doc(id).set(searchData);
      searchHistory.insert(0, searchData);
    } catch (_) {}
  }

  List<SpeciesModel> getDerivedSpecies() {
    final groups = <String, List<ObservationModel>>{};
    for (final obs in observations) {
      final key = obs.species.trim().capitalizeFirst ?? obs.species.trim();
      groups.putIfAbsent(key, () => []).add(obs);
    }

    final speciesList = <SpeciesModel>[];
    groups.forEach((name, obsList) {
      final uniqueVideos = obsList.map((o) => o.videoName).toSet().length;
      final latestDate = obsList.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
      
      speciesList.add(SpeciesModel(
        name: name,
        observationCount: obsList.length,
        videoCount: uniqueVideos,
        lastObserved: latestDate,
        observations: obsList,
      ));
    });

    // Sort by observation count descending
    speciesList.sort((a, b) => b.observationCount.compareTo(a.observationCount));
    return speciesList;
  }

  int getMonthlySearchCount() {
    final now = DateTime.now();
    return searchHistory.where((s) {
      final tsStr = s['timestamp'] as String?;
      if (tsStr == null) return false;
      final date = DateTime.tryParse(tsStr);
      if (date == null) return false;
      return date.year == now.year && date.month == now.month;
    }).length;
  }
}
