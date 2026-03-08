import '../../models/Malikshi/emotion_record.dart';

/// Singleton service to hold the temporary state of a Malikshi session
/// across different routes.
class MalikshiDataService {
  static final MalikshiDataService _instance = MalikshiDataService._internal();
  factory MalikshiDataService() => _instance;
  MalikshiDataService._internal();

  List<EmotionRecord> currentRecords = [];

  void reset() {
    currentRecords = [];
  }

  int calculateScore() {
    if (currentRecords.isEmpty) return 75;
    final combined = currentRecords.where((r) => r.source == 'combined').toList();
    if (combined.isEmpty) return 75;
    
    final negativeCount = combined.where((r) => r.isNegative).length;
    final ratio = negativeCount / combined.length;
    return ((1 - ratio) * 100).round();
  }
}
