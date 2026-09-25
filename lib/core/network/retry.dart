import 'dart:async';
import 'dart:math';

/// Retries [action] with exponential backoff (+ small jitter).
/// [shouldRetry] decides whether a given error is worth retrying;
/// defaults to retrying on any error.
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 400),
  bool Function(Object error)? shouldRetry,
}) async {
  var attempt = 0;
  var delay = initialDelay;
  while (true) {
    attempt++;
    try {
      return await action();
    } catch (error) {
      final retry = shouldRetry?.call(error) ?? true;
      if (!retry || attempt >= maxAttempts) rethrow;
      await Future.delayed(
        delay + Duration(milliseconds: Random().nextInt(200)),
      );
      delay *= 2;
    }
  }
}
