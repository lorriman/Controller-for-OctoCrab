import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import '../services/shared_preferences_service.dart';
import '../services/utils.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appproviders.dart';

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
    final double sz = 75;
    final start = 200;
    final int maxCount = 250;
    final int incr = 20;
    final shades = [200];

    final size=MediaQuery.of(context).size;
    final  landscape=size.height<size.width;
    final portrait=!landscape;

    return Wrap( direction : Axis.horizontal,
      children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text('Colors', textScaleFactor: 1.8),
            ),
          ),
          //SizedBox(width: 50, height: 0),

        ]),
        Container(
          padding: EdgeInsets.all(16),
          child: Wrap( //direction : Axis.vertical,
              children: [
            InkWell(//splashColor : Color(0x00000000),
              onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(255, 255, 255, 1);
              Navigator.of(context).pop();},
              child: Ink(
                  height: sz, width: sz, color: Color.fromRGBO(255, 255, 255, 1)),
            ),
            //todo: horrible kludge to get my pastel colors. Maybe revisit one day
            for (int x in shades)
              for (int i = start; i < 255; i += incr)
                InkWell(onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(255, i, x, 1);
                Navigator.of(context).pop();},
                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(255, i, x, 1)),
                ),
            for (int x in shades)
              for (int i = start; i < 255; i += incr)
                InkWell( onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(255, x, i, 1);
                Navigator.of(context).pop();},
                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(255, x, i, 1)),
                ),
            for (int x in shades)
              for (int i = start; i < 255; i += incr)
                InkWell(onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(i, 255, x, 1);
                Navigator.of(context).pop();},
                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(i, 255, x, 1)),
                ),
            for (int x in shades)
              for (int i = start; i < 255; i += incr)
                InkWell( onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(x, 255, i, 1);
                Navigator.of(context).pop();},
                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(x, 255, i, 1)),
                ),
            for (int x in shades)
              for (int i = start; i < 255; i += incr)
                InkWell(onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(i, x , 255, 1);
                Navigator.of(context).pop();},
                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(i, x, 255, 1)),
                ),
            for (int x in shades)
              for (int i = start; i < 255; i += incr)
                InkWell( onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(x, i, 255, 1);
                Navigator.of(context).pop();},

                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(x, i, 255, 1)),
                ),

              for (int i = 200; i < 255; i += incr)
                InkWell(
                  onTap: (){  ref.read(colorProvider.notifier).state =Color.fromRGBO(i,i,i, 1);
                    Navigator.of(context).pop();
                    },
                  child: Ink(
                      height: sz, width: sz, color: Color.fromRGBO(i, i, i, 1)),
                ),


          ]),
        )
      ],
    );
  }
}
