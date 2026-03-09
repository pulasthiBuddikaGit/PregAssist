class MaternalRiskResult {
  final int risk;
  final double confidence;
  final String topContributor;
  final Map<String, double> importance;
  final List<String> advice;

  MaternalRiskResult({
    required this.risk,
    required this.confidence,
    required this.topContributor,
    required this.importance,
    required this.advice,
  });

  factory MaternalRiskResult.fromJson(Map<String, dynamic> json) {
    return MaternalRiskResult(
      risk: json['risk_level'] ?? 0,
      confidence: ((json['percentage'] ??
                  json['confidence_percentage'] ??
                  json['confidence'] ??
                  0) as num)
              .toDouble(),
      topContributor: json['top_contributor'] ?? 'N/A',
      importance: Map<String, double>.from(
        (json['importance'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      advice: List<String>.from(json['advice'] ?? []),
    );
  }
}