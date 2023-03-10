import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';


enum ViewDensity {
  compact(Icons.density_small_outlined, -16, 'compact view'),
  medium(Icons.density_medium_outlined, -8, 'medium view'),
  large(Icons.density_large_outlined, 0, 'larger view');

  final IconData icon;
  final String semanticLabel;
  final int densityAdjust;

  const ViewDensity(this.icon, this.densityAdjust, this.semanticLabel);
}

/// Copyright Andrea Bozito, with modifications.
/// Notable additions and classes by Greg Lorriman as noted.

final sharedPreferencesServiceProvider =
    Provider<SharedPreferencesService>((ref) => throw UnimplementedError());

class SharedPreferencesService {
  SharedPreferencesService(this.sharedPreferences);

  final SharedPreferences sharedPreferences;

  static const onboardingCompleteKey = 'onboardingComplete';
  static const viewDensityKey = 'viewDensity';

  Future<void> setViewDensity(ViewDensity viewDensity) async {
    await sharedPreferences.setString(viewDensityKey, viewDensity.name);
  }

  ViewDensity getViewDensity() {
    final str = sharedPreferences.getString(viewDensityKey);
    if (str == null) return ViewDensity.large;
    return ViewDensity.values.firstWhere((element) => element.name == str);
  }

  Future<void> setOnboardingComplete() async {
    await sharedPreferences.setBool(onboardingCompleteKey, true);
  }

  //Greg Lorriman
  Future<void> resetForTesting() async {
    await sharedPreferences.setBool(onboardingCompleteKey, false);
  }

  bool isOnboardingComplete() =>
      sharedPreferences.getBool(onboardingCompleteKey) ?? false;
}
