import '../routes.dart';

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is! String || route.isEmpty) {
    return AppRoutes.home;
  }
  return route.startsWith('/') ? route : '/$route';
}
