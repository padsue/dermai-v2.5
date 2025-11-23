import 'package:dermai/utils/skin_conditions_catalog.dart';

class SkinConditionHelper {
  static final Map<String, String> _descriptions = {};
  static final Map<String, String> _categories = {};

  static bool _isInitialized = false;

  static void _initialize() {
    if (_isInitialized) return;

    skinConditionsByCategory.forEach((category, conditions) {
      for (var condition in conditions) {
        if (condition['name'] != null) {
          final name = condition['name']!;
          if (condition['description'] != null) {
            _descriptions[name] = condition['description']!;
            // Also store lowercase version for flexible matching
            _descriptions[name.toLowerCase()] = condition['description']!;
          }
          _categories[name] = category;
          _categories[name.toLowerCase()] = category;
        }
      }
    });
    _isInitialized = true;
  }

  static String? getDescription(String conditionName) {
    _initialize();
    // Try exact match first, then lowercase
    return _descriptions[conditionName] ??
        _descriptions[conditionName.toLowerCase()];
  }

  static String? getCategory(String conditionName) {
    _initialize();
    // Try exact match first, then lowercase
    return _categories[conditionName] ??
        _categories[conditionName.toLowerCase()];
  }
}
