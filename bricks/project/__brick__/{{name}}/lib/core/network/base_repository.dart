import 'package:dio/dio.dart';

/// 所有仓库的抽象基类。
///
/// 职责极简：仅持有 [Dio] 实例，作为所有 Repository 的统一基类型与 DI 注入点。
///
/// **本类不做任何响应处理**：不解析、不校验 HTTP 状态码、不抛任何异常。
/// 发起请求、解析响应、判断业务错误、决定如何抛出——全部交给各 Repository
/// 的公开方法自行处理（这正是 CLI 生成时"用户拥有、可自由修改"的那部分）。
/// 框架不替用户做任何业务或文案假设。
///
/// Abstract base class for all repositories.
///
/// Its only job is to hold the [Dio] instance, serving as the common base
/// type and DI injection point. It performs no response parsing, no status
/// checks, and throws no exceptions — all of that is the responsibility of
/// each concrete repository's public methods.
abstract class BaseRepository {
  const BaseRepository({required this.dio});

  /// 当前仓库持有的 Dio 实例。
  final Dio dio;
}
