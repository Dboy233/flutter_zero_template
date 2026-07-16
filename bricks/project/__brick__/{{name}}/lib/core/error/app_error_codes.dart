/// 应用内部错误码与常见 HTTP 错误码常量。
///
/// 内部错误使用负数命名空间，避免与 HTTP 状态码（100~599）冲突。
/// 常见 HTTP 码也以常量形式集中管理，方便业务层统一引用。
///
/// Application-internal and common HTTP error codes.
///
/// Internal errors use negative values so they never collide with HTTP status
/// codes (100~599). Common HTTP codes are also centralized so business code
/// can reference them consistently.
abstract final class AppErrorCodes {
  const AppErrorCodes._();

  // ── 应用内部错误码（负数命名空间） ─────────────────────────────────

  /// 未知/未分类错误。
  ///
  /// Unknown / catch-all error.
  static const int unknown = -1;

  /// JSON 模型 fromJson 解析失败（嵌套响应结构不符预期）。
  ///
  /// JSON model fromJson parsing failed (nested response structure mismatch).
  static const int parseFromJson = -2;

  /// API 返回数据为空（预期为对象时得到 null）。
  ///
  /// API response data is null when an object was expected.
  static const int parseNullData = -3;

  /// API 返回数据类型不符预期（预期对象但得到 List/Scalar 等）。
  ///
  /// API response data type does not match expectations.
  static const int parseWrongType = -4;

  /// 设备无网络连接 / DNS 失败。
  ///
  /// No network connectivity or DNS failure.
  static const int noConnection = -5;

  // 后续内部错误继续在此追加：-6, -7, ...
  // Additional internal errors continue here: -6, -7, ...

  // ── 常见 HTTP 4xx 客户端错误码 ────────────────────────────────────

  /// Bad Request — 请求参数/格式错误。
  static const int badRequest = 400;

  /// Unauthorized — 未认证（Token 缺失/过期）。
  static const int unauthorized = 401;

  /// Forbidden — 已认证但无权限。
  static const int forbidden = 403;

  /// Not Found — 资源不存在。
  static const int notFound = 404;

  /// Method Not Allowed — 请求方法不支持。
  static const int methodNotAllowed = 405;

  /// Request Timeout — 请求超时（同时覆盖 Dio 连接/发送/接收超时）。
  static const int requestTimeout = 408;

  /// Conflict — 资源冲突（如并发修改）。
  static const int conflict = 409;

  /// Gone — 资源已永久删除。
  static const int gone = 410;

  /// Payload Too Large — 请求体过大。
  static const int payloadTooLarge = 413;

  /// Unsupported Media Type — 媒体类型不支持。
  static const int unsupportedMediaType = 415;

  /// Unprocessable Entity — 格式合法但语义校验失败。
  static const int unprocessableEntity = 422;

  /// Too Many Requests — 请求过于频繁/限流。
  static const int tooManyRequests = 429;

  // ── 常见 HTTP 5xx 服务端错误码 ────────────────────────────────────

  /// Internal Server Error — 服务器内部错误。
  static const int internalServerError = 500;

  /// Not Implemented — 功能未实现。
  static const int notImplemented = 501;

  /// Bad Gateway — 网关/代理收到无效响应。
  static const int badGateway = 502;

  /// Service Unavailable — 服务不可用（过载/维护）。
  static const int serviceUnavailable = 503;

  /// Gateway Timeout — 网关超时。
  static const int gatewayTimeout = 504;
}
