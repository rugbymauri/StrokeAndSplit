import 'dart:async';

import 'package:clock/clock.dart';

/// Tries [connect] again and again within [window], waiting [retryDelay]
/// after each failure, and returns the first connection; null when [window]
/// ran out or [cancelled] turned true meanwhile.
///
/// A connection made after [cancelled] turned true goes to [discard]. Shared
/// by the rower and the heart rate strap (Design D7).
Future<T?> reconnectWithin<T>({
  required Future<T> Function() connect,
  required Duration window,
  required Duration retryDelay,
  required bool Function() cancelled,
  required Future<void> Function(T connection) discard,
}) async {
  final deadline = clock.now().add(window);
  while (!cancelled()) {
    final remaining = deadline.difference(clock.now());
    if (remaining <= Duration.zero) return null;
    try {
      final connection = await connect().timeout(remaining);
      if (cancelled()) {
        await discard(connection);
        return null;
      }
      return connection;
    } catch (_) {
      final left = deadline.difference(clock.now());
      if (left <= Duration.zero) return null;
      await Future<void>.delayed(left < retryDelay ? left : retryDelay);
    }
  }
  return null;
}
