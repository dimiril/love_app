import 'package:dio/dio.dart';

class DioService {
  static const String _apiKey = "d8eb2352788544059b98001d72975f368a437be4eac40aa9468d33cd87d6abb0";
  static const String _appVersion = "1.0.0";

  static final DioService _instance = DioService._internal();
  factory DioService() => _instance;

  late Dio dio;

  bool _forcedUpdateShown = false;

  DioService._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          "Accept": "application/json",
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll({
            "X-API-KEY": _apiKey,
            "X-APP-VERSION": _appVersion,
          });
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            print("❌ Unauthorized Error: ${e.response?.data}");
          } else if (e.response?.statusCode == 426) {
            print("⚠️ App version outdated - forced update required");

            if (!_forcedUpdateShown && _onForcedUpdate != null) {
              _forcedUpdateShown = true;
              _onForcedUpdate!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  void Function()? _onForcedUpdate;
  void setForcedUpdateCallback(void Function() callback) {
    _onForcedUpdate = callback;
  }

  void resetForcedUpdateFlag() {
    _forcedUpdateShown = false;
  }
}
