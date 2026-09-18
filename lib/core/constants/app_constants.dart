class AppConstants {
  static const String appName = 'EcoVision';
  static const String appTagline = 'Environmental Footage & Multimodal Video Search';

  // Default V-Modal scope settings
  static const String defaultProjectId = 'ecovision';
  static const String defaultCollectionName = 'wildlife_research';
  static const String defaultStreamName = 'nature_footage';
  static const String defaultIndexType = 'vid_img_emb';

  // Research-themed semantic chips
  static const List<Map<String, String>> semanticChips = [
    {'label': '🐾 Predation', 'query': 'hunting predation animal attack'},
    {'label': '💧 Drinking', 'query': 'animal drinking water'},
    {'label': '👤 Human Intrusion', 'query': 'people walking human presence'},
    {'label': '🌙 Nocturnal', 'query': 'animals at night low light'},
    {'label': '🐘 Herd Activity', 'query': 'group of animals herd social interaction'},
  ];
}
