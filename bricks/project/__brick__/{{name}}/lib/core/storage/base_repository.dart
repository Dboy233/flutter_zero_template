import 'package:dio/dio.dart';

import '../error/app_error_codes.dart';
import '../error/app_exception.dart';
import '../network/dio_client.dart';

/// 所有仓库的抽象基类。
///
/// 提供通用 CRUD 模式、JSON 解析工具和统一的 [DioClient] 访问。
/// 具体仓库继承此类，定义自己的领域专用方法。
///
/// ## 动机
///
/// 没有基类时，每个仓库都要重复 JSON 解析、空安全检查和错误处理。
/// [BaseRepository] 消除了这些样板代码。
///
/// ## 用法
///
/// ```dart
/// class UserRepository extends BaseRepository {
///   UserRepository({required super.client});
///
///   Future<List<User>> fetchUsers({CancelToken? cancelToken}) async {
///     final response = await client.get<List<dynamic>>('/users',
///         cancelToken: cancelToken);
///     return parseList(response, User.fromJson);
///   }
/// }
/// ```
///
/// Abstract base class for all repositories.
///
/// Provides common CRUD patterns, JSON parsing utilities, and
/// unified access to [DioClient]. Concrete repositories inherit
/// from this class and define their own domain-specific methods.
///
/// ## Motivation
///
/// Without a base class, every repository duplicates JSON parsing,
/// null-safety checks, and error logic. [BaseRepository] eliminates
/// that boilerplate.
///
/// ## Usage
///
/// ```dart
/// class UserRepository extends BaseRepository {
///   UserRepository({required super.client});
///
///   Future<List<User>> fetchUsers({CancelToken? cancelToken}) async {
///     final response = await client.get<List<dynamic>>('/users',
///         cancelToken: cancelToken);
///     return parseList(response, User.fromJson);
///   }
/// }
/// ```
abstract class BaseRepository {
  /// 创建绑定到给定 HTTP [client] 的仓库。
  ///
  /// 测试中可将 client 替换为 mock 对象。
  ///
  /// Creates a repository bound to the given HTTP [client].
  ///
  /// The client can be swapped with a mock in tests.
  const BaseRepository({required this.client});

  /// 本仓库所有网络请求使用的 HTTP 客户端。
  ///
  /// The HTTP client used for all network requests in this repository.
  final DioClient client;

  /// 将 API 响应（其 [Response.data] 预期为 JSON 数组）解析为 [T] 类型列表。
  ///
  /// 当 [Response.data] 为 null 时返回空列表。
  ///
  /// Parses an API response whose [Response.data] is
  /// expected to be a JSON list.
  ///
  /// Returns an empty list when [Response.data] is null.
  List<T> parseList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;
    if (data == null) return [];

    if (data is! List) {
      throw ParseException(
        null,
        code: AppErrorCodes.parseWrongType,
        originalError: data,
      );
    }

    return data.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }

  /// 将 API 响应（其 [Response.data] 预期为单个 JSON 对象）解析为 [T] 类型。
  ///
  /// 当 [Response.data] 为 null 时返回 `null`。
  ///
  /// Parses an API response whose [Response.data] is expected to be a single
  /// JSON object.
  ///
  /// Returns `null` when [Response.data] is null.
  T? parseSingle<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;
    if (data == null) return null;

    if (data is! Map<String, dynamic>) {
      throw ParseException(
        null,
        code: AppErrorCodes.parseWrongType,
        originalError: data,
      );
    }

    return fromJson(data);
  }

  /// 将完整 API 响应解析为 freezed / json_serializable 模型。
  ///
  /// 适用场景：后端返回嵌套结构（如 `{data: [...], total: N}`），
  /// 开发者定义 freezed 响应模型，`fromJson` 自动处理嵌套解析。
  ///
  /// 与 [parseList] / [parseSingle] 的区别：
  /// - [parseList] 只处理 `Response.data` 是纯数组的扁平响应
  /// - [parseSingle] 只处理 `Response.data` 是纯对象的扁平响应
  /// - [parseResponse] 处理任意嵌套结构，交给 freezed 模型的 fromJson
  ///
  /// 用法：
  /// ```dart
  /// // 1. 定义 freezed 响应模型
  /// @freezed
  /// class ApiResponse with _$ApiResponse {
  ///   const factory ApiResponse({
  ///     required List<UserModel> data,
  ///     required int total,
  ///   }) = _ApiResponse;
  ///   factory ApiResponse.fromJson(Map<String, dynamic> json) =>
  ///       _$ApiResponseFromJson(json);
  /// }
  ///
  /// // 2. Repository 里一步解析
  /// final result = parseResponse<ApiResponse>(
  ///   response, ApiResponse.fromJson);
  /// return result.data;  // freezed 属性，类型安全
  /// ```
  ///
  /// Parses the full API response into a freezed / json_serializable model.
  ///
  /// Use when the backend returns a nested structure
  /// (e.g. `{data: [...], total: N}`). Define a freezed response model
  /// whose `fromJson` handles the nested parsing automatically.
  ///
  /// Unlike [parseList] / [parseSingle]:
  /// - [parseList] only handles flat responses where `Response.data` is a
  ///   plain array.
  /// - [parseSingle] only handles flat responses where `Response.data` is a
  ///   plain object.
  /// - [parseResponse] handles any nested structure by delegating to the
  ///   freezed model's `fromJson`.
  T parseResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      try {
        return fromJson(data);
      } on AppException {
        rethrow;
      } catch (e) {
        throw ParseException(
          null,
          code: AppErrorCodes.parseFromJson,
          originalError: e,
        );
      }
    }

    if (data == null) {
      throw const ParseException(
        null,
        code: AppErrorCodes.parseNullData,
      );
    }

    throw ParseException(
      null,
      code: AppErrorCodes.parseWrongType,
      originalError: data,
    );
  }

  /// 解析 HTTP 成功但业务状态码失败的包装型响应。
  ///
  /// 先检查 HTTP 状态码为 200~299；非 200 响应直接抛 [ServerException]，
  /// 由上层 `ErrorHandler` 按 HTTP 码兜底翻译。状态码确认后，将响应体通过
  /// [parseBody] 转换为结构化类型 [B]，后续 [isSuccess]、[extractCode]、
  /// [extractMessage]、[extractData] 均在类型化的 [B] 上访问，无需反复
  /// `as Map<String, dynamic>`。
  ///
  /// 常见于国内后端接口返回 200 但 body 内携带
  /// `{code: 10001, message: "库存不足", data: null}` 的场景。框架不猜测
  /// 字段名，由业务方提供解析与提取逻辑；本方法只负责统一抛出
  /// [BusinessException]。
  ///
  /// [parseBody] 将原始响应体转换为结构化类型 [B]（如 freezed 响应模型）。
  /// [isSuccess] 判断业务是否成功；返回 `false` 时抛出异常。
  /// [extractCode] 可选，从结构化响应体提取业务错误码。
  /// [extractMessage] 可选，从结构化响应体提取服务端文案（已翻译）。
  /// [extractData] 从成功响应体提取最终 [T] 数据。
  ///
  /// 用法：
  /// ```dart
  /// Future<User> getUser(String id) async {
  ///   final response = await client.get('/users/$id');
  ///   return parseBusinessResponse<User, ApiResponse<User>>(
  ///     response,
  ///     parseBody: (body) => ApiResponse<User>.fromJson(
  ///       body as Map<String, dynamic>,
  ///     ),
  ///     isSuccess: (body) => body.code == 0,
  ///     extractCode: (body) => body.code,
  ///     extractMessage: (body) => body.message,
  ///     extractData: (body) => body.data,
  ///   );
  /// }
  /// ```
  ///
  /// Parses a wrapped response where HTTP status is 200-299 but the business-level
  /// status code indicates failure.
  ///
  /// First checks the HTTP status code is in the 200-299 range; non-2xx responses
  /// throw [ServerException] immediately so the upper `ErrorHandler` can localize
  /// by HTTP code. After confirming the status, the raw body is converted to a
  /// structured type [B] via [parseBody]. Then [isSuccess], [extractCode],
  /// [extractMessage] and [extractData] operate on the typed [B] without repeated
  /// `as Map<String, dynamic>` casts.
  ///
  /// Common in APIs that return `{code: 10001, message: "...", data: null}`.
  /// The framework does not assume field names; the caller provides parsing and
  /// extraction logic, and this helper only unifies the throw of
  /// [BusinessException].
  T parseBusinessResponse<T, B>(
    Response<dynamic> response, {
    required B Function(dynamic body) parseBody,
    required bool Function(B body) isSuccess,
    required T Function(B body) extractData,
    int? Function(B body)? extractCode,
    String? Function(B body)? extractMessage,
  }) {
    final statusCode = response.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw ServerException(
        null,
        code: statusCode ?? AppErrorCodes.unknown,
        originalError: response,
      );
    }

    final B body = parseBody(response.data);
    if (isSuccess(body)) {
      return extractData(body);
    }
    throw BusinessException(
      extractMessage?.call(body),
      code: extractCode?.call(body),
      originalError: body,
    );
  }
}
