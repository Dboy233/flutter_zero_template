/// API 接口与配置常量。
///
/// 将后端相关路径集中管理，避免在业务代码中硬编码 URL。
///
///
/// API endpoint and configuration constants.
///
/// Keep all backend-related paths in one place so the rest of the app
/// does not hard-code URLs.
class ApiConstants {
  ApiConstants._();

  /// [DioClient] 使用的基础 URL。
  ///
  /// 当前为 JSONPlaceholder 示例 API，实际开发时替换为你的后端地址。
  ///
  ///
  /// Base URL used by [DioClient].
  ///
  /// Currently set to JSONPlaceholder demo API.
  /// Replace with your actual backend URL in production.
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  /// 文章列表端点路径。
  ///
  /// 支持 `_page`（从 1 开始）和 `_limit` 分页参数。
  ///
  ///
  /// Posts list endpoint path.
  ///
  /// Supports `_page` (1-based) and `_limit` pagination parameters.
  static const String posts = '/posts';
}
