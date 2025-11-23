class SeverityHelper {
  static const Map<String, SeverityLevel> _severityMap = {
    'harmless': SeverityLevel.harmless,
    'mild': SeverityLevel.mild,
    'moderate': SeverityLevel.moderate,
    'severe': SeverityLevel.severe,
    'unknown': SeverityLevel.unknown,
  };

  /// Extracts severity from a disease label (e.g., "acne_mild" → "mild")
  static SeverityInfo parseDiseaseLabel(String label) {
    if (label.isEmpty) {
      return SeverityInfo(
        diseaseName: 'Unknown',
        severity: SeverityLevel.unknown,
        severityText: 'Unknown',
      );
    }

    final parts = label.split('_');
    if (parts.length < 2) {
      return SeverityInfo(
        diseaseName: _formatDiseaseName(label),
        severity: SeverityLevel.unknown,
        severityText: 'Unknown',
      );
    }

    final diseaseName = parts.sublist(0, parts.length - 1).join(' ');
    final severityText =
        parts.last.toLowerCase().replaceAll('(harmless)', '').trim();

    return SeverityInfo(
      diseaseName: _formatDiseaseName(diseaseName),
      severity: _severityMap[severityText] ?? SeverityLevel.unknown,
      severityText: _capitalizeFirst(severityText),
    );
  }

  static String _formatDiseaseName(String name) {
    return name.split('-').map((word) => _capitalizeFirst(word)).join(' ');
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String getSeverityDescription(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.harmless:
        return 'Generally harmless condition that typically requires no treatment';
      case SeverityLevel.mild:
        return 'Mild condition that may benefit from over-the-counter treatments';
      case SeverityLevel.moderate:
        return 'Moderate condition that may require medical consultation';
      case SeverityLevel.severe:
        return 'Severe condition that requires immediate medical attention';
      case SeverityLevel.unknown:
        return 'Severity level could not be determined';
    }
  }
}

enum SeverityLevel {
  harmless,
  mild,
  moderate,
  severe,
  unknown,
}

class SeverityInfo {
  final String diseaseName;
  final SeverityLevel severity;
  final String severityText;

  SeverityInfo({
    required this.diseaseName,
    required this.severity,
    required this.severityText,
  });
}
