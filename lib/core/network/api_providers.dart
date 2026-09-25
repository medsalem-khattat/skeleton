import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Not used by any screen yet - available once a real REST API exists.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
