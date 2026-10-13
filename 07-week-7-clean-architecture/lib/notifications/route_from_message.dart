import '../core/format.dart';
import '../routes.dart';

String routeFromMessage(Map<String, dynamic> data) {
  return normalizeRoute(data['route'], fallback: AppRoutes.home);
}
