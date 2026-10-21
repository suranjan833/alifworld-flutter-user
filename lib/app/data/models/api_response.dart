import 'package:dio/dio.dart' as dio;

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final String? errorCode;
  final int? statusCode;

  ApiResponse({
    required this.isSuccess,
    this.data,
    this.message,
    this.errorCode,
    this.statusCode,
  });

  factory ApiResponse.fromResponse(
    dio.Response<dynamic> response,
    T Function(dynamic json)? fromJson,
  ) {
    final status = response.statusCode ?? 500;
    final isOk = status >= 200 && status < 300;
    final responseData = response.data;

    if (isOk && responseData != null) {
      dynamic dataPayload = responseData;
      String? msg;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data')) {
          dataPayload = responseData['data'];
        }
        if (responseData.containsKey('message')) {
          msg = responseData['message']?.toString();
        }
      }

      T? parsedData;
      if (fromJson != null && dataPayload != null) {
        try {
          parsedData = fromJson(dataPayload);
        } catch (e) {
          // If parsing failed or payload was null
          parsedData = null;
        }
      } else if (dataPayload is T) {
        parsedData = dataPayload;
      }

      return ApiResponse<T>(
        isSuccess: true,
        data: parsedData,
        message: msg ?? 'Success',
        statusCode: status,
      );
    } else {
      String? errCode;
      String? errMessage;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('error') && responseData['error'] is Map) {
          final errorObj = responseData['error'] as Map<String, dynamic>;
          errCode = errorObj['code']?.toString();
          errMessage = errorObj['message']?.toString();
        } else if (responseData.containsKey('message')) {
          errMessage = responseData['message']?.toString();
        }
      }

      return ApiResponse<T>(
        isSuccess: false,
        data: null,
        message: errMessage ?? response.statusMessage ?? 'Something went wrong',
        errorCode: errCode ?? 'HTTP_$status',
        statusCode: status,
      );
    }
  }

  factory ApiResponse.error(String errorMessage, {String? code, int? status}) {
    return ApiResponse<T>(
      isSuccess: false,
      data: null,
      message: errorMessage,
      errorCode: code ?? 'CLIENT_ERROR',
      statusCode: status ?? 400,
    );
  }
}
