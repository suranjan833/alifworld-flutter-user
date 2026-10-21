// ignore_for_file: library_prefixes

import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as DIO;

import 'app_config.dart';

Map<String, String> _getHeaders() {
  final token = getBox.read(USER_TOKEN) ?? '';
  final sessionCookie = getBox.read('SESSION_COOKIE') ?? '';
  String cookieHeader = '';
  if (sessionCookie.toString().isNotEmpty) {
    cookieHeader = sessionCookie.toString();
  } else if (token.toString().isNotEmpty) {
    cookieHeader = 'alifworld_session=$token';
  }

  return {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
    if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
    if (token.toString().isNotEmpty) 'authtoken': token.toString(),
    if (token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

void _saveCookieFromResponse(DIO.Response response) {
  try {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      for (var cookie in setCookie) {
        if (cookie.contains('alifworld_session=')) {
          final match = RegExp(r'alifworld_session=([^;]+)').firstMatch(cookie);
          if (match != null && match.group(1) != null) {
            final sessionVal = match.group(1)!.trim();
            if (sessionVal.isNotEmpty && sessionVal != 'deleted') {
              getBox.write('SESSION_COOKIE', 'alifworld_session=$sessionVal');
              getBox.write(USER_TOKEN, sessionVal);
              getBox.write(IS_USER_LOGGED_IN, true);
            }
          }
        }
      }
    }
  } catch (_) {}
}

DIO.Dio _createDio() {
  return DIO.Dio(
    DIO.BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: _getHeaders(),
    ),
  );
}

Future<DIO.Response<dynamic>> dioGet(String endUrl) async {
  var dio = _createDio();
  var finalUrl = "$BASE_URL$endUrl";

  try {
    var response = await dio.get(
      finalUrl,
      options: DIO.Options(
        validateStatus: (status) => true,
      ),
    );
    _saveCookieFromResponse(response);
    if (isDebugMode.value) {
      log("\n\nGET: $finalUrl\nHEADERS:\n${jsonEncode(_getHeaders())}\nSTATUS CODE: ${response.statusCode}\n${jsonEncode(response.data)}\n\n");
    }
    return response;
  } catch (e) {
    return DIO.Response(
      requestOptions: DIO.RequestOptions(path: endUrl),
      statusCode: 500,
      statusMessage: "Something went wrong",
      data: {"message": "Something went wrong"},
    );
  }
}

Future<DIO.Response<dynamic>> dioDelete(String endUrl) async {
  var dio = _createDio();
  var finalUrl = "$BASE_URL$endUrl";

  try {
    var response = await dio.delete(
      finalUrl,
      options: DIO.Options(
        validateStatus: (status) => true,
      ),
    );
    _saveCookieFromResponse(response);
    if (isDebugMode.value) {
      log("\n\nDELETE: $finalUrl\nHEADERS:\n${jsonEncode(_getHeaders())}\nSTATUS CODE: ${response.statusCode}\n${jsonEncode(response.data)}\n\n");
    }
    return response;
  } catch (e) {
    return DIO.Response(
      requestOptions: DIO.RequestOptions(path: endUrl),
      statusCode: 500,
      statusMessage: "Something went wrong",
      data: {"message": "Something went wrong"},
    );
  }
}

Future<DIO.Response<dynamic>> dioPost({
  Map<String, dynamic>? data,
  String? endUrl,
  bool? isFile,
  bool isJson = false,
  Map<String, String>? customHeaders,
}) async {
  var finalUrl = "$BASE_URL${endUrl ?? ''}";
  var dio = _createDio();
  if (customHeaders != null) {
    dio.options.headers.addAll(customHeaders);
  }
  if (isJson) {
    dio.options.headers['Content-Type'] = 'application/json';
  }
  try {
    var response = await dio.post(
      finalUrl,
      data: isJson ? (data ?? {}) : (data != null ? DIO.FormData.fromMap(data) : null),
      options: DIO.Options(
        validateStatus: (status) => true,
        contentType: isJson ? DIO.Headers.jsonContentType : null,
      ),
    );
    _saveCookieFromResponse(response);
    if (isDebugMode.value) {
      log("\n\nPOST: $finalUrl\nHEADERS:\n${jsonEncode(_getHeaders())}\n${(isFile ?? false) ? '' : 'BODY:${jsonEncode(data)}'}\nSTATUS CODE: ${response.statusCode}\n${jsonEncode(response.data)}\n\n");
    }
    return response;
  } catch (e) {
    log(e.toString());
    return DIO.Response(
      requestOptions: DIO.RequestOptions(path: endUrl ?? ""),
      statusCode: 500,
      statusMessage: "Something went wrong",
      data: {"message": "Something went wrong"},
    );
  }
}

Future<DIO.Response<dynamic>> dioPut({
  Map<String, dynamic>? data,
  String? endUrl,
  bool isJson = true,
}) async {
  var finalUrl = "$BASE_URL${endUrl ?? ''}";
  var dio = _createDio();
  if (isJson) {
    dio.options.headers['Content-Type'] = 'application/json';
  }
  try {
    var response = await dio.put(
      finalUrl,
      data: isJson ? (data ?? {}) : (data != null ? DIO.FormData.fromMap(data) : null),
      options: DIO.Options(
        validateStatus: (status) => true,
        contentType: isJson ? DIO.Headers.jsonContentType : null,
      ),
    );
    _saveCookieFromResponse(response);
    if (isDebugMode.value) {
      log("\n\nPUT: $finalUrl\nHEADERS:\n${jsonEncode(_getHeaders())}\nBODY:${jsonEncode(data)}\nSTATUS CODE: ${response.statusCode}\n${jsonEncode(response.data)}\n\n");
    }
    return response;
  } catch (e) {
    log(e.toString());
    return DIO.Response(
      requestOptions: DIO.RequestOptions(path: endUrl ?? ""),
      statusCode: 500,
      statusMessage: "Something went wrong",
      data: {"message": "Something went wrong"},
    );
  }
}

Future<DIO.Response<dynamic>> dioPatch({
  Map<String, dynamic>? data,
  String? endUrl,
  bool isJson = true,
}) async {
  var finalUrl = "$BASE_URL${endUrl ?? ''}";
  var dio = _createDio();
  if (isJson) {
    dio.options.headers['Content-Type'] = 'application/json';
  }
  try {
    var response = await dio.patch(
      finalUrl,
      data: isJson ? (data ?? {}) : (data != null ? DIO.FormData.fromMap(data) : null),
      options: DIO.Options(
        validateStatus: (status) => true,
        contentType: isJson ? DIO.Headers.jsonContentType : null,
      ),
    );
    _saveCookieFromResponse(response);
    if (isDebugMode.value) {
      log("\n\nPATCH: $finalUrl\nHEADERS:\n${jsonEncode(_getHeaders())}\nBODY:${jsonEncode(data)}\nSTATUS CODE: ${response.statusCode}\n${jsonEncode(response.data)}\n\n");
    }
    return response;
  } catch (e) {
    log(e.toString());
    return DIO.Response(
      requestOptions: DIO.RequestOptions(path: endUrl ?? ""),
      statusCode: 500,
      statusMessage: "Something went wrong",
      data: {"message": "Something went wrong"},
    );
  }
}
