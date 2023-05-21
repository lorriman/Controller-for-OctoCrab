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
    final double sz=20;
    final int maxCount=50;
    final int mult=40;
    return Scaffold(
      appBar: NeumorphicAppBar(
        //  automaticallyImplyLeading: true,
        title: FittedBox(
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 10),
              Text(
                'Colors',
                textScaleFactor: 1.4,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Wrap(children : [
        for(int i=10;i<maxCount;i++) Container(height: sz, width : sz, color: Color.fromRGBO(  mult*i,  255~/i,  175,  1)),
        for(int i=10;i<maxCount;i++) Container(height: sz, width : sz, color: Color.fromRGBO(  mult*i,  175, 255~/i ,  1)),
        for(int i=10;i<maxCount;i++) Container(height: sz, width : sz, color: Color.fromRGBO(  175, mult*i  , 255~/i ,  1)),
        for(int i=10;i<maxCount;i++) Container(height: sz, width : sz, color: Color.fromRGBO(  255~/i, mult*i  , 175 ,  1)),
        for(int i=10;i<maxCount;i++) Container(height: sz, width : sz, color: Color.fromRGBO(  175,  255~/i ,mult*i,  1)),
        for(int i=10;i<maxCount;i++) Container(height: sz, width : sz, color: Color.fromRGBO(  255~/i, 175, mult*i  ,  1)),

      ]),
    );

  }
}