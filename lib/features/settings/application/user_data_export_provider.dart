import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/user_data_export_repository.dart';

final userDataExportRepositoryProvider = Provider<UserDataExportRepository>(
  (ref) => UserDataExportRepository(ref.watch(firestoreProvider)),
);
