import 'package:dio/dio.dart';
import '../models/transaction.dart';
import '../models/summary.dart';

/// Wraps Dio HTTP errors into user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // With `adb reverse tcp:3000 tcp:3000` the physical device resolves localhost:3000
  // directly to the host machine. Switch back to 10.0.2.2:3000 for emulators.
  static const String _baseUrl = 'http://localhost:3000';

  late final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  // ─── Transactions ────────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactions() async {
    try {
      final res = await _dio.get('/transactions');
      return (res.data as List).map((j) => Transaction.fromJson(j)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Transaction> createTransaction(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/transactions', data: data);
      return Transaction.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Transaction> getTransaction(String id) async {
    try {
      final res = await _dio.get('/transactions/$id');
      return Transaction.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Transaction> updateTransaction(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('/transactions/$id', data: data);
      return Transaction.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Summary ─────────────────────────────────────────────────────────────────

  Future<Summary> getSummary() async {
    try {
      final res = await _dio.get('/summary');
      return Summary.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Error normalisation ─────────────────────────────────────────────────────

  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final code = e.response!.statusCode;
      final body = e.response!.data;

      if (body is Map<String, dynamic>) {
        // Our server sends { errors: [...] } for validation failures
        if (body['errors'] is List) {
          final msgs = (body['errors'] as List).join(', ');
          return ApiException('Validation error: $msgs', statusCode: code);
        }
        // Our server sends { error: "..." } for 404s
        if (body['error'] is String) {
          return ApiException(body['error'] as String, statusCode: code);
        }
      }
      return ApiException('Server error ($code)', statusCode: code);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            'Connection timed out. Check your network.');
      case DioExceptionType.connectionError:
        return const ApiException(
            'Cannot reach the server. Make sure the backend is running.');
      default:
        return ApiException('Unexpected error: ${e.message}');
    }
  }
}
