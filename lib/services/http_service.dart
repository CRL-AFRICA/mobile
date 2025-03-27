import 'package:dio/dio.dart';
import '../utils/toast.dart'; 

class HttpService {
  final Dio _dio = Dio(BaseOptions(
    // baseUrl: dotenv.env['API_BASE_URL'] ?? '',
    baseUrl: 'http://20.160.237.234:9080/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  // Handle errors
  void _handleError(DioException e) {
    String errorMessage = 'Something went wrong';

    if (e.response != null) {
      errorMessage = e.response?.data['message'] ?? 'Server error';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timed out';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Server took too long to respond';
    } else if (e.type == DioExceptionType.unknown) {
      errorMessage = 'Check your internet connection';
    }

    showToast(errorMessage, isError: true);
  }

  // GET request
  Future<Response?> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      Response response = await _dio.get(endpoint, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // POST request
  Future<Response?> post(String endpoint, {dynamic data}) async {
    try {
      Response response = await _dio.post(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // DELETE request
  Future<Response?> delete(String endpoint, {dynamic data}) async {
    try {
      Response response = await _dio.delete(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }
}
