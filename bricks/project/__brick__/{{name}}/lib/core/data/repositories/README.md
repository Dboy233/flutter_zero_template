# 共享仓库（Shared Repositories）

跨多个 feature 共享的数据仓库放在本目录。

- **何时上移**：某仓库被 2 个及以上 feature 调用时，从 `features/<name>/data/repositories/` 提到这里（解决「settings 想用 user 数据」的正确方式，而不是 import user feature 源码）。仅单 feature 使用的仓库留在原处。
- **约定**：继承 `BaseRepository`（`core/storage/base_repository.dart`），复用 `parseList` / `parseSingle` / `parseResponse`；文件名 `lower_snake_case` 以 `_repository` 结尾。
- **DI 注册**：统一在 `core/data/shares_repositories.dart` 的 `register` 中登记为 `lazySingleton`，**不要改 `injection_base.dart`**。调用方通过 `getIt<XxxRepository>()` 取用，无需互引 feature。

示例（注册见 `shares_repositories.dart`）：

```dart
class UserRepository extends BaseRepository {
  const UserRepository({required super.client});

  Future<UserModel> fetchCurrentUser({CancelToken? cancelToken}) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiConstants.currentUser,
      cancelToken: cancelToken,
    );
    return parseSingle(response, UserModel.fromJson) ??
        (throw const ParseException('user not found'));
  }
}
```
