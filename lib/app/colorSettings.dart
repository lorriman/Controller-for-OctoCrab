import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import '../services/shared_preferences_service.dart';
import '../services/utils.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorSettingsView extends ConsumerStatefulWidget {
  ColorSettingsView({super.key, required this.title});

  final String title;

  @override
  ConsumerState<ColorSettingsView> createState() => _ColorSettingsViewState();
}

class _ColorSettingsViewState extends ConsumerState<ColorSettingsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final double sz=120;
    final start=200;
    final int maxCount=250;
    final int incr=20;
    final shades=[200];
    
    return Container(padding : EdgeInsets.all(16),
      child: Wrap(children : [
        Container(height: sz, width: sz, color: Color.fromRGBO( 255, 255, 255, 1)),
        

        for( int x in shades)
        for(int i=start;i<255;i+=incr)
          Container(height: sz, width: sz, color: Color.fromRGBO(255, i, x, 1)),
        for( int x in shades)
          for(int i=start;i<255;i+=incr)
            Container(height: sz, width: sz, color: Color.fromRGBO(255, x, i, 1)),

      for( int x in shades)
        for(int i=start;i<255;i+=incr)
          Container(height: sz, width: sz, color: Color.fromRGBO(i, 255, x, 1)),
        for( int x in shades)
          for(int i=start;i<255;i+=incr)
            Container(height: sz, width: sz, color: Color.fromRGBO(x, 255, i, 1)),

      for( int x in shades)
        for(int i=start;i<255;i+=incr)
          Container(height: sz, width: sz, color: Color.fromRGBO( i, x, 255, 1)),
      for( int x in shades)
        for(int i=start;i<255;i+=incr)
          Container(height: sz, width: sz, color: Color.fromRGBO( x, i, 255, 1)),

        ]),
    );


  }
}