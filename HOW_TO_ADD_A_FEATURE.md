# How to add a feature

This guide adds a small example feature, **notes** (a per-user list of notes), end to end. Use the same steps for any feature. Copy the pattern, change the names.

Every feature has three layers and is built as one vertical slice:

```
features/notes/
  data/          model + repository (Firebase access only here)
  application/   Riverpod providers (state)
  presentation/  screens and widgets
```

## Checklist

- [ ] 1. Create the feature folders
- [ ] 2. Model and repository (`data/`)
- [ ] 3. Providers (`application/`)
- [ ] 4. Screen (`presentation/`)
- [ ] 5. Add the route
- [ ] 6. Add the navigation entry (if it is a main tab)
- [ ] 7. Update Firestore rules
- [ ] 8. Write tests
- [ ] 9. `flutter analyze`, `flutter test`, run the app, commit

---

## 1. Create the folders

```
lib/features/notes/data
lib/features/notes/application
lib/features/notes/presentation
```

## 2. Model and repository

`lib/features/notes/data/note.dart`

```dart
class Note {
  const Note({required this.id, required this.title});

  final String id;
  final String title;
}
```

`lib/features/notes/data/notes_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import 'note.dart';

class NotesRepository {
  NotesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db
      .collection(AppConfig.usersCollection)
      .doc(uid)
      .collection('notes');

  Stream<List<Note>> watch(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Note(id: d.id, title: (d.data()['title'] as String?) ?? ''))
            .toList());
  }

  Future<void> add(String uid, String title) {
    return _col(uid).add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid, String noteId) => _col(uid).doc(noteId).delete();
}
```

Rule: **UI code never imports Firebase.** Only repositories do.

## 3. Providers

`lib/features/notes/application/notes_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/note.dart';
import '../data/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(firestoreProvider));
});

/// The signed-in user's notes (empty list when signed out).
final notesProvider = StreamProvider<List<Note>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <Note>[]);
  return ref.watch(notesRepositoryProvider).watch(user.uid);
});
```

For actions that can fail and show a loading state (create, save), follow the pattern in `features/auth/application/auth_providers.dart` (an `AsyncNotifier` with a `_run` helper).

## 4. Screen

`lib/features/notes/presentation/notes_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../application/notes_providers.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user == null) return;
          ref.read(notesRepositoryProvider).add(user.uid, 'New note');
        },
        child: const Icon(Icons.add),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Could not load notes.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No notes yet.'))
            : ListView(
                children: [
                  for (final n in items) ListTile(title: Text(n.title)),
                ],
              ),
      ),
    );
  }
}
```

Every screen handles the three states: **loading, error, data**.

## 5. Add the route

`lib/core/router/app_routes.dart`: add a constant:

```dart
static const notes = '/notes';
```

`lib/core/router/app_router.dart`: import the screen and add a `StatefulShellBranch` (for a main tab) next to the others:

```dart
StatefulShellBranch(routes: [
  GoRoute(
    path: AppRoutes.notes,
    builder: (context, state) => const NotesScreen(),
  ),
]),
```

For a screen that is not a tab (a detail or form screen), add a plain `GoRoute` in the top-level `routes:` list instead, and open it with `context.push(...)`.

## 6. Add the navigation entry

`lib/features/home/presentation/home_shell.dart`: add a matching `NavigationDestination`. **The order of destinations must match the order of the branches in the router.**

```dart
NavigationDestination(
  icon: Icon(Icons.note_outlined),
  selectedIcon: Icon(Icons.note),
  label: 'Notes',
),
```

## 7. Update Firestore rules

Add to `firestore.rules` (inside `match /documents`) and publish in the Firebase console:

```
match /users/{uid}/notes/{noteId} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

Never leave a new collection open. Every collection needs a rule.

## 8. Write tests

Follow the pattern in `test/`:

- Put fake repositories in `test/helpers/` (in-memory, no Firebase).
- Override the repository provider in the test with `overrideWithValue(fake)`.
- Unit-test logic, widget-test the screen states (empty, data, error).

## 9. Verify and commit

```
flutter analyze
flutter test
flutter run
git add .
git commit -m "feat: add notes"
```

## Definition of done for a feature

- Works end to end on a device (UI, state, data)
- Firestore rules cover any new collection
- Analyzer clean, tests pass
- Screens handle loading, error and empty states
- No Firebase imports outside `data/`
- No project-specific values outside `core/config/app_config.dart`
