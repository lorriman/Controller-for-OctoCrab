import 'package:flutter/material.dart';

MaterialColor getMaterialColor(Color color) => Colors.primaries
    .firstWhere((element) => element.value == color.value);