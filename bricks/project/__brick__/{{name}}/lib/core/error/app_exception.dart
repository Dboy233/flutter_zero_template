import 'package:{{name}}/core/effect/ui_effect.dart';

import 'app_error_codes.dart';

/// 应用级异常抽象基类。
///
/// 每个异常可携带面向用户的 [message]（来自服务端且已由服务端翻译，
/// 或 `null`）和可选 [code]（HTTP 状态码或内部哨兵码，见 [AppErrorCodes]），
/// 以及 [originalError]。
///
/// 本类是 **抽象**（abstract）而非密封（sealed）的：任何库都能直接
/// `extends AppException` 添加自定义业务异常，无需修改本文件。
/// [ErrorHandler] 将底层异常（DioException 等）映射到内建子类，使应用其余
/// 部分无需接触原始传输层错误。展示时优先用 [toToastEffect]。
///
/// Abstract base class for application-specific exceptions.
///
/// Each exception carries an optional user-facing [message] (server-provided
/// and already translated, or `null`) and an optional [code] (an HTTP status
/// or an internal sentinel code — see [AppErrorCodes]), plus [originalError].
/// This class is **abstract** (not sealed): any library can `extends
/// AppException` to add custom business exceptions without editing this file.
/// [ErrorHandler] maps low-level exceptions (DioException, etc.) into the
/// built-in subclasses so the rest of the app never touches raw transport-layer
/// errors. Prefer [toToastEffect] for display.
abstract class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  /// 适合在 toast 中展示的可读消息（通常来自服务端，已翻译）。
  /// 可能为空——此时前端应使用 [code] 决定兜底翻译。
  ///
  /// Human-readable message suitable for display in a toast (usually from the
  /// server, already translated). May be null — the client should then pick a
  /// localized fallback based on [code].
  final String? message;

  /// 错误码：HTTP 状态码（401/404/500…）或应用内部哨兵码
  ///（见 [AppErrorCodes]：unknown=-1、parseFromJson=-2、parseNullData=-3、
  /// parseWrongType=-4、noConnection=-5）。前端据此映射兜底文案。
  ///
  /// Error code: an HTTP status (401/404/500…) or an internal sentinel
  /// (see [AppErrorCodes]: unknown=-1, parseFromJson=-2, parseNullData=-3,
  /// parseWrongType=-4, noConnection=-5). The client maps it to a localized
  /// fallback.
  final int? code;

  /// 触发此异常的原始底层异常。
  ///
  /// The original low-level exception that triggered this one.
  final Object? originalError;

  /// 转换为一次性 Toast 副作用。
  ///
  /// 优先使用服务端原始 [message]（已翻译）；否则把 [code] 透传给
  /// [ToastEffect.code]，由 UI 层按码翻译（如"请求出错: 404"）。
  ///
  /// Converts to a one-time toast effect.
  ///
  /// Prefers the server [message]; otherwise forwards [code] to
  /// [ToastEffect.code] so the UI layer localizes it (e.g. "Request failed: 404").
  ToastEffect toToastEffect() => ToastEffect(message: message, code: code);
}

/// 设备无网络连接或 DNS 解析失败时抛出。
///
/// Raised when the device has no network connectivity or DNS fails.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// 服务器返回错误响应（4xx / 5xx）时抛出。
///
/// Raised when the server returns an error response (4xx / 5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}

/// 401 / token 过期等认证场景时抛出。
///
/// Raised on 401 / token-expired scenarios.
final class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// 请求超时（连接 / 发送 / 接收）时抛出。
///
/// Raised when the request times out (connect / send / receive).
final class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code, super.originalError});
}

/// JSON 解析或响应数据结构不符预期时抛出。
///
/// Raised when JSON parsing fails or response data structure
/// does not match expectations (e.g. expected Map but got List).
final class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});
}

/// HTTP 成功（200）但业务状态码失败时抛出。
///
/// 常见于包装型响应体，例如 `{code: 10001, message: "库存不足", data: null}`。
/// 该异常由业务仓库在 [BaseRepository.parseBusinessResponse] 等辅助方法中
/// 主动抛出；框架不猜测具体字段名，但提供统一类型供 UI 层消费。
///
/// Raised when the HTTP status is successful (200) but the business-level
/// status code indicates failure, e.g. `{code: 10001, message: "...", data: null}`.
/// Business repositories throw this explicitly via helpers such as
/// [BaseRepository.parseBusinessResponse]; the framework does not assume field
/// names, but provides a unified exception type for the UI layer.
final class BusinessException extends AppException {
  const BusinessException(super.message, {super.code, super.originalError});
}

/// 无法进一步分类的错误通用类型。
///
/// Catch-all for errors that cannot be classified further.
final class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.originalError});
}
