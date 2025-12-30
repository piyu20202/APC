import 'package:flutter/widgets.dart';

/// Global route observer so screens can pause work (timers, streams, etc.)
/// when they are not visible (e.g. another route is pushed on top).
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();


