import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../notifications/push_service.dart';

final pushServiceProvider = Provider<PushService?>((ref) => null);
final firebaseInitializationErrorProvider = Provider<String?>((ref) => null);
