import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/settings/data/user_data_export_repository.dart';

void main() {
  test(
    'export serializes profile and notification timestamps as ISO dates',
    () {
      final generatedAt = DateTime.utc(2026, 10, 4, 14);
      final json = serializeUserDataExport(
        account: const {'uid': 'user-1', 'email': 'user@example.com'},
        profile: {
          'name': 'Sam',
          'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 3)),
        },
        notifications: [
          {
            'id': 'notification-1',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 2)),
          },
        ],
        generatedAt: generatedAt,
      );
      final export = jsonDecode(json) as Map<String, dynamic>;

      expect(export['format'], 'skeleton-account-export-v1');
      expect(export['generatedAt'], '2026-10-04T14:00:00.000Z');
      expect(export['profile']['updatedAt'], '2026-10-03T00:00:00.000Z');
      expect(
        export['notifications'][0]['createdAt'],
        '2026-10-02T00:00:00.000Z',
      );
      expect(json, isNot(contains('fcmTokens')));
    },
  );
}
