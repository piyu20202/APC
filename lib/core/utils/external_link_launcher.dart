import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reliable external URL opening across iOS/Android.
///
/// Do not gate on [canLaunchUrl] — it often returns false on iOS and Android 11+
/// even when a browser or the YouTube app can handle the link.
class ExternalLinkLauncher {
  static const youtubeChannelUrls = [
    'https://www.youtube.com/@APC-AutomotionPlus',
    'https://youtube.com/@APC-AutomotionPlus',
    'https://m.youtube.com/@APC-AutomotionPlus',
    'https://www.youtube.com/results?search_query=APC+Automotion+Plus',
  ];

  static List<LaunchMode> get _defaultModes {
    if (!kIsWeb && Platform.isAndroid) {
      return const [
        LaunchMode.platformDefault,
        LaunchMode.externalApplication,
        LaunchMode.externalNonBrowserApplication,
      ];
    }

    return const [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ];
  }

  static Future<bool> openUrl(
    String url, {
    List<LaunchMode>? modes,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    for (final mode in modes ?? _defaultModes) {
      try {
        if (await launchUrl(uri, mode: mode)) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }

    return false;
  }

  static Future<bool> openYouTubeChannel() async {
    for (final url in youtubeChannelUrls) {
      if (await openUrl(url)) {
        return true;
      }
    }
    return false;
  }
}
