import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        return 'Terjadi kesalahan pada server (Kode: ${error.response?.statusCode}).';
      default:
        return 'Tidak dapat terhubung ke jaringan. Periksa koneksi internet Anda.';
    }
  }
  return 'Terjadi kesalahan: $error';
}