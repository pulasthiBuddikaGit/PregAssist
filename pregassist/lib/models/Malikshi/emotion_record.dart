/// Represents a single emotion data point captured during a chat session.
class EmotionRecord {
  /// The index of the interaction (0-based).
  final int messageIndex;

  /// The detected emotion label (e.g., "Happy", "Neutral", "Sad", "Fear", "Anger").
  final String emotionLabel;

  /// Optional confidence score (0.0 – 1.0).
  final double? confidence;

  /// When this record was captured.
  final DateTime timestamp;

  /// Source of the detection: "text" or "image".
  final String source;

  const EmotionRecord({
    required this.messageIndex,
    required this.emotionLabel,
    this.confidence,
    required this.timestamp,
    required this.source,
  });

  /// Maps an emotion label to a numeric Y-axis value for charting.
  /// Anger=0, Fear=1, Sad=2, Neutral=3, Happy=4
  double get numericValue {
    switch (emotionLabel) {
      case 'Anger':
        return 0;
      case 'Fear':
        return 1;
      case 'Sad':
        return 2;
      case 'Neutral':
        return 3;
      case 'Happy':
        return 4;
      default:
        return 3; // default to Neutral
    }
  }

  /// Whether this emotion is considered negative.
  bool get isNegative =>
      emotionLabel == 'Sad' ||
      emotionLabel == 'Fear' ||
      emotionLabel == 'Anger';
}
