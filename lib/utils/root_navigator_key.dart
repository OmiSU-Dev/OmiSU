import 'package:flutter/material.dart';

/// Root [MaterialApp] navigator — used for post-game navigation when the
/// launcher's [BuildContext] may already be disposed.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
