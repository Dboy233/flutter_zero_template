import 'package:dio/dio.dart';

import 'app_error_codes.dart';
import 'app_exception.dart';
import 'server_message_extractor.dart';

/// 将原始异常映射为类型化的 [AppException] 实例。
///
/// 本类是可实例化的策略类，BLoC 通常通过 [BlocErrorHandlerMixin] 使用。
/// 需要自定义服务端消息提取策略时，在构造时传入 [serverMessageExtractor]；
/// 默认按 `message` / `error` / `errorMsg` / `msg` 候选顺序取值。
///
/// ## 用法
///
/// ```dart
/// final handler = ErrorHandler();
/// try {
///   await fetchData();
/// } catch (e, stackTrace) {
///   final ex = handler.handle(e);
///   // ex?.message 可以安全地在 toast 中展示
/// }
/// ```
///
/// 这是**唯一的转换点**——所有 BLoC 的错误路径都经过此处，保证一致的
/// 用户体验。
///
/// Maps raw exceptions into typed [AppException] instances.
///
/// This class is instantiable and usually consumed by [BlocErrorHandlerMixin].
/// Pass a custom [serverMessageExtractor] to the constructor if your backend
/// uses different response fields; the default tries `message` / `error` /
/// `errorMsg` / `msg` in order.
///
/// ## Usage
///
/// ```dart
/// final handler = ErrorHandler();
/// try {
///   await fetchData();
/// } catch (e, stackTrace) {
///   final ex = handler.handle(e);
///   // ex?.message is safe to show in a toast
/// }
/// ```
///
/// This is the **single conversion point** — all BLoC error paths go through
/// here, guaranteeing consistent UX.
class ErrorHandler {
  /// 创建 [ErrorHandler]。
  ///
  /// [serverMessageExtractor] 覆盖默认的服务端消息提取策略。
  ///
  /// Creates an [ErrorHandler].
  ///
  /// [serverMessageExtractor] overrides the default server-message extraction
  /// strategy.
  ErrorHandler({ServerMessageExtractor? serverMessageExtractor})
      : serverMessageExtractor = serverMessageExtractor ?? ServerMessageExtractor();

  /// 服务端错误消息提取策略（Strategy 模式）。
  ///
  /// 默认按 `message` / `error` / `errorMsg` / `msg` 候选顺序取值。
  /// 若你的后端字段名不同，构造 [ErrorHandler] 时传入自定义实例，或在外部
  /// 直接替换该字段：
  ///
  /// ```dart
  /// final handler = ErrorHandler();
  /// handler.serverMessageExtractor.keys = ['msg', 'errorMessage'];
  /// ```
  ///
  /// Server error message extraction strategy (Strategy pattern).
  ///
  /// Defaults to trying `message` / `error` / `errorMsg` / `msg` in order.
  /// Pass a custom instance to the [ErrorHandler] constructor, or replace this
  /// field directly:
  ///
  /// ```dart
  /// final handler = ErrorHandler();
  /// handler.serverMessageExtractor.keys = ['msg', 'errorMessage'];
  /// ```
  ServerMessageExtractor serverMessageExtractor;

  /// 将任意 [error] 转换为类型化的 [AppException]。
  ///
  /// 当错误是被取消的请求（主动中止）时返回 `null`，应静默忽略。
  ///
  /// Converts any [error] into a typed [AppException].
  ///
  /// Returns `null` when the error was a cancelled request (intentional
  /// abort) and should be silently ignored.
  AppException? handle(Object error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is AppException) {
      return error;
    }

    // 非 Dio 异常：不写死文案，交给前端按 code(AppErrorCodes.unknown) 兜底翻译。
    // Non-Dio exceptions: no hard-coded text; the client localizes via
    // code (AppErrorCodes.unknown) as a fallback.
    if (error is Exception) {
      return UnknownException(
        null,
        code: AppErrorCodes.unknown,
        originalError: error,
      );
    }

    return UnknownException(
      null,
      code: AppErrorCodes.unknown,
      originalError: error,
    );
  }

  /// 当错误是主动取消时返回 `true`，此时**不应**弹出 toast 或更新状态。
  ///
  /// Returns `true` when the error was intentionally cancelled and
  /// should **not** trigger a toast or state update.
  bool isCancelled(Object error) {
    return error is DioException && error.type == DioExceptionType.cancel;
  }

  // ── Internal helpers ──────────────────────────────────────────────

  AppException? _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        // 主动取消的请求应静默忽略：返回 null，调用方据此跳过 toast / 状态更新。
        // Intentionally cancelled requests are silently ignored: return null so
        // callers skip the toast / state update.
        return null;

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // 不写死文案：连接/发送/接收超时统一按 HTTP 408 兜底翻译。
        // No hard-coded text: client-side connect/send/receive timeouts are
        // treated as HTTP 408 (Request Timeout) for localization.
        return TimeoutException(
          null,
          code: AppErrorCodes.requestTimeout,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.connectionError:
        // 不写死文案：交给前端按 code(AppErrorCodes.noConnection) 兜底翻译。
        // No hard-coded text: let the client localize via
        // code (AppErrorCodes.noConnection) as a fallback.
        return NetworkException(
          null,
          code: AppErrorCodes.noConnection,
          originalError: error,
        );

      default:
        // 不写死文案：交给前端按 code(AppErrorCodes.unknown) 兜底翻译。
        // No hard-coded text: let the client localize via
        // code (AppErrorCodes.unknown) as a fallback.
        return UnknownException(
          null,
          code: AppErrorCodes.unknown,
          originalError: error,
        );
    }
  }

  AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final int? code = statusCode;

    // 优先使用服务端返回的消息（字段名不固定，交给可替换的提取策略）。
    // 服务端未返回可读文案时 message 为 null，由 UI 层按 [code] 在前端本地化。
    // Prefer the server-provided message (field name is not fixed — delegate to
    // the swappable extractor). When the server returns no readable text,
    // message stays null and the UI layer localizes it on the client side via
    // [code].
    final data = error.response?.data;
    final String? message = serverMessageExtractor.extract(data);

    if (statusCode == AppErrorCodes.unauthorized ||
        statusCode == AppErrorCodes.forbidden) {
      return AuthException(message, code: code, originalError: error);
    }

    return ServerException(message, code: code, originalError: error);
  }
}
