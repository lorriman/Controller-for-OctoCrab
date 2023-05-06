import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:package_info_plus/package_info_plus.dart';


void aboutDialog(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  showAboutDialog(
    context: context,
    applicationName: 'Controller for Octocrab',
    applicationVersion: 'v. ${info.version.toString()} +${info.buildNumber}',
    applicationIcon: Icon(Icons.info_outline),
  );
}


snackBar(context, msg, {bool error = false}) {
  final snackBar = SnackBar(
      content: Row(children: [
        if (error)
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 50,
          ),
        if (error) SizedBox(width: 40),
        Text(
          msg,
          textScaleFactor: 1.4,
        )
      ]));

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}


Future<bool?> shutdownDialogBuilder(BuildContext context) {
  return showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: Icon(size: 70, Icons.power_settings_new, color: Colors.red),
        //title: const Text('Shutdown'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30))),
        content: const Text(
            'Are you sure you wish to shutdown the remote device?',
            textScaleFactor: 1.3),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Yes', textScaleFactor: 2),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel ', textScaleFactor: 2),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      );
    },
  );
}
