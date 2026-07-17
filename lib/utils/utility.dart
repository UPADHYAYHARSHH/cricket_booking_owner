import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

import 'package:url_launcher/url_launcher.dart';

class Logger {
  static var tag = '';
  static var cloud = '☁️';
  static var success = '✅️';
  static var info = '💡';
  static var warning = '🃏️';
  static var error = '💔';
  static var response = '🌱';

  static var logIcon = '✏️';

  ///used to show the log in the app.
  static void log({
    var tag = 'indicator',
    var message = '',
    var logIcon = 'ℹ️️',
  }) {
    if (!kReleaseMode) {
      Logger.logIcon = logIcon;
      Logger.tag = tag;
      dev.log(
        '${Logger.logIcon} -------------------------------------------------------------- ${Logger.logIcon}',
      );
      dev.log(tag + '\t  ' + message);
      dev.log(
        '------------------------------------------------------------------',
      );
    }
  }
}

Future<void> launchInBrowser(downloadUrl) async {
  Logger.log(message: downloadUrl);
  if (!await launchUrl(
    Uri.parse(downloadUrl),
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('Could not launch $downloadUrl');
  }
}
