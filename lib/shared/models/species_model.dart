import 'observation_model.dart';

class SpeciesModel {
  final String name;
  final int observationCount;
  final int videoCount;
  final DateTime lastObserved;
  final List<ObservationModel> observations;

  const SpeciesModel({
    required this.name,
    required this.observationCount,
    required this.videoCount,
    required this.lastObserved,
    required this.observations,
  });
}
