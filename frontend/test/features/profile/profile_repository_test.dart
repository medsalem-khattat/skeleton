import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/profile/data/profile_repository.dart';

void main() {
  test(
    'rolls back the Auth display name when profile persistence fails',
    () async {
      final calls = <String>[];
      final saveError = StateError('profile write failed');

      await expectLater(
        updateProfileNameWithRollback(
          updateAuthName: () async => calls.add('update'),
          persistProfile: () async {
            calls.add('persist');
            throw saveError;
          },
          rollbackAuthName: () async => calls.add('rollback'),
        ),
        throwsA(same(saveError)),
      );

      expect(calls, ['update', 'persist', 'rollback']);
    },
  );

  test('reports when both profile save and Auth rollback fail', () async {
    final saveError = StateError('profile write failed');
    final rollbackError = StateError('Auth rollback failed');

    await expectLater(
      updateProfileNameWithRollback(
        updateAuthName: () async {},
        persistProfile: () async => throw saveError,
        rollbackAuthName: () async => throw rollbackError,
      ),
      throwsA(
        isA<ProfileNameSyncException>()
            .having((error) => error.profileError, 'profileError', saveError)
            .having(
              (error) => error.rollbackError,
              'rollbackError',
              rollbackError,
            ),
      ),
    );
  });

  test('does not persist if updating the Auth display name fails', () async {
    var profilePersisted = false;

    await expectLater(
      updateProfileNameWithRollback(
        updateAuthName: () async => throw StateError('Auth update failed'),
        persistProfile: () async => profilePersisted = true,
        rollbackAuthName: () async {},
      ),
      throwsStateError,
    );

    expect(profilePersisted, isFalse);
  });
}
