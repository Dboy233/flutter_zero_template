import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'app.dart';
import 'core/auth/token_storage.dart';
import 'core/di/injection.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/interceptors/auth_interceptor.dart';
import 'core/network/interceptors/locale_interceptor.dart';

/// 开发环境入口。
///
/// 连接本地调试服务器，日志全开。
/// 使用：`flutter run -t lib/main_dev.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Injection().registerAll();

  getIt.registerLazySingleton<Dio>(
    () =>
        Dio(BaseOptions(
          baseUrl: 'http://192.168.1.100:8080',
        ))
          ..interceptors.addAll([
            AuthInterceptor(tokenStorage: getIt<TokenStorage>()),
            LocaleInterceptor(localeProvider: getIt<LocaleProvider>()),
            PrettyDioLogger(
              requestHeader: true,
              requestBody: true,
              responseHeader: true,
            ),
          ]),
  );

  runApp(const App());
}
