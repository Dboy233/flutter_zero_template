import 'package:dio/dio.dart';

import '../../localization/locale_provider.dart';

/// 语言环境拦截器。
///
/// 在每次请求的 `onRequest` 中，把当前语言码写入 `Accept-Language` 头，
/// 让后端据此返回已翻译的错误文案（前端无需自行处理错误国际化）。
///
/// 若后端未返回翻译后的 `message`，则由业务层把异常转换为 [ToastEffect]
/// （如带 [ToastEffect.l10nCode] 或 [ToastEffect.code]），UI 层按码在前端本地化。
///
/// Locale interceptor.
///
/// Writes the current language code into the `Accept-Language` header on every
/// request so the backend can return already-translated error text (the client
/// does not need to localize errors itself).
///
/// If the backend returns no translated `message`, the business layer converts
/// the exception into a [ToastEffect] (e.g. with [ToastEffect.l10nCode] or
/// [ToastEffect.code]) and the UI layer localizes it on the client side.
class LocaleInterceptor extends Interceptor {
  /// 创建 [LocaleInterceptor]。
  ///
  /// [localeProvider] 提供无 context 的语言码读取。
  ///
  /// Creates a [LocaleInterceptor]. [localeProvider] supplies the language code
  /// without a [BuildContext].
  LocaleInterceptor({required this.localeProvider});

  /// 语言环境来源。
  ///
  /// Locale source.
  final LocaleProvider localeProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 告诉后端当前语言，让其在错误响应里直接返回已翻译文案。
    // Tell the backend the current language so it returns translated error
    // text in its responses.
    options.headers['Accept-Language'] = localeProvider.languageCode;
    handler.next(options);
  }
}
