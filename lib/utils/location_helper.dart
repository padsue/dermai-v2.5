import 'dart:convert';
import 'package:flutter/services.dart';

class LocationHelper {
  static Map<String, dynamic>? _locationsData;
  static bool _isLoaded = false;

  static Future<void> loadLocations() async {
    if (_isLoaded) return;

    final String jsonString =
        await rootBundle.loadString('assets/locations.json');
    _locationsData = json.decode(jsonString);
    _isLoaded = true;
  }

  static List<String> getRegions() {
    if (_locationsData == null) return [];
    return _locationsData!.keys.toList()..sort();
  }

  static List<String> getProvinces(String region) {
    if (_locationsData == null || !_locationsData!.containsKey(region))
      return [];
    final regionData = _locationsData![region] as Map<String, dynamic>;
    return regionData.keys.toList()..sort();
  }

  static List<String> getMunicipalities(String region, String province) {
    if (_locationsData == null || !_locationsData!.containsKey(region))
      return [];
    final regionData = _locationsData![region] as Map<String, dynamic>;
    if (!regionData.containsKey(province)) return [];
    final provinceData = regionData[province] as Map<String, dynamic>;
    return provinceData.keys.toList()..sort();
  }

  static List<String> getBarangays(
      String region, String province, String municipality) {
    if (_locationsData == null || !_locationsData!.containsKey(region))
      return [];
    final regionData = _locationsData![region] as Map<String, dynamic>;
    if (!regionData.containsKey(province)) return [];
    final provinceData = regionData[province] as Map<String, dynamic>;
    if (!provinceData.containsKey(municipality)) return [];
    final barangays = provinceData[municipality] as List<dynamic>;
    return barangays.map((e) => e.toString()).toList()..sort();
  }

  static String formatAddress({
    required String barangay,
    required String municipality,
    required String province,
    required String region,
  }) {
    return '$barangay, $municipality, $province, $region';
  }
}
