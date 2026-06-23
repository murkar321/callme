import 'package:flutter/material.dart';

/// Shared navigator key so code outside the widget tree (e.g. a
/// notification-tap callback) can push routes without a BuildContext.
///
/// Lives in its own file (not main.dart) so other files — like
/// notification_router.dart — can import it without creating a
/// circular dependency on main.dart.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();