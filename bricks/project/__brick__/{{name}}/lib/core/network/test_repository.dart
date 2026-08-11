import 'package:dio/dio.dart';
import 'package:{{name}}/core/network/base_repository.dart';

/// 请求模型（CLI 生成：json_serializable / freezed）。
class TestRequest {
  const TestRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

/// 响应模型（CLI 生成：json_serializable / freezed）。
class TestResponse {
  const TestResponse({required this.token});

  factory TestResponse.fromJson(Map<String, dynamic> json) =>
      TestResponse(token: json['token'] as String);

  final String token;
}

/// CLI 生成（可重生成，用户不碰）：机械请求方法，仅发请求、返回原始 Response。
mixin TestRepositoryMixin on BaseRepository {
  Future<Response<dynamic>> _toLogin(
    TestRequest request, {
    CancelToken? cancelToken,
  }) {
    return dio.post(
      '/login',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
  }
}

/// CLI 生成（首次生成后不再覆盖，用户可自由修改）：
/// 为 TestRepository 混入请求类 [TestRepositoryMixin]，并暴露其中的公开方法。
class TestRepository extends BaseRepository with TestRepositoryMixin {
  TestRepository({required super.dio});

  /// CLI 生成的最基础调用：不参与任何逻辑与业务内容。
  /// 响应如何处理、错误如何抛出，全部由开发者自行决定。
  Future<TestResponse> toLogin(
    TestRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await _toLogin(request, cancelToken: cancelToken);
    // 最基础反序列化；类型判断 / 业务错误判断留给开发者。
    return TestResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
