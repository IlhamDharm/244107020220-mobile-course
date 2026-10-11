import 'package:dio/dio.dart';

String apiErrorMessage(DioException error) {
  if (error.response?.statusCode == 401) {
    return 'Sesi Anda telah berakhir. Silakan login kembali.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi terlalu lama. Periksa jaringan Anda dan coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.badResponse:
      return 'Server sedang bermasalah. Silakan coba lagi nanti.';
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
