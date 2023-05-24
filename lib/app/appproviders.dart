import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../services/shared_preferences_service.dart';
import 'config.dart';


final colorProvider = StateProvider<Color>((ref) {

  ref.listenSelf((previous, next) {
    final prefService = ref.read(sharedPreferencesServiceProvider);
    prefService.sharedPreferences.setInt('color',next.value);
  });

  //return Color(0xFFFFFFFF);
  final prefService = ref.read(sharedPreferencesServiceProvider);
   final colorInt=prefService.sharedPreferences.getInt('color') ?? 0xFFFFFFFF;
  return Color(colorInt);
});


final darkModeProvider = StateProvider<bool>((ref) {

  ref.listenSelf((previous, next) {
    final sharedPreferencesService = ref.read(
        sharedPreferencesServiceProvider);
    sharedPreferencesService
        .sharedPreferences
        .setBool('darkMode', next);
  });

  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getBool('darkMode') ?? false;
});

final brightnessProvider = StateProvider<int>((ref) {

  ref.listenSelf((previous, next) {
    final sharedPreferencesService = ref
        .read(sharedPreferencesServiceProvider);
    sharedPreferencesService.sharedPreferences
        .setInt('brightness', next);
  });

  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getInt('brightness') ?? 125;
});

final rateLimitBrightnessProvider = StateProvider<bool>((ref) {
  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getString(sharedPrefKey_rateLimitBrightness)=='true';
});

