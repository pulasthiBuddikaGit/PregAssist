import 'package:flutter/foundation.dart';

/// Singleton [ValueNotifier] that tracks whether there is an unread
/// critical alert.  Any widget can listen to this notifier and rebuild
/// automatically when the flag changes.
///
/// Usage:
///   // Set badge when a high-risk alert arrives:
///   criticalAlertState.value = true;
///
///   // Clear badge when the user opens Critical Alerts screen:
///   criticalAlertState.value = false;
final ValueNotifier<bool> criticalAlertState = ValueNotifier<bool>(false);
