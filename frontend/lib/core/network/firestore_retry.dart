import 'package:cloud_firestore/cloud_firestore.dart';

import 'retry.dart';

/// Whether a Firestore/Firebase error is transient and worth retrying.
bool isTransientFirebaseError(Object error) {
  if (error is FirebaseException) {
    const transientCodes = {
      'unavailable',
      'deadline-exceeded',
      'internal',
      'aborted',
      'resource-exhausted',
    };
    return transientCodes.contains(error.code);
  }
  return false;
}

/// Wraps a single Firestore read/write with retry + exponential backoff.
/// Use for one-off calls (get/set/update), not for .snapshots() streams,
/// which Firestore's own SDK already keeps alive and reconnects.
///
/// Example:
///   final snap = await firestoreRetry(() => doc.get());
///   await firestoreRetry(() => doc.set(data, SetOptions(merge: true)));
Future<T> firestoreRetry<T>(Future<T> Function() action) => withRetry(
      action,
      shouldRetry: isTransientFirebaseError,
    );
