String compactDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String normalizeRoute(Object? route, {String fallback = '/'}) {
  if (route is! String || route.isEmpty) return fallback;
  return route.startsWith('/') ? route : '/$route';
}
