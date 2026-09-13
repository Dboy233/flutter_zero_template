# data_sources（数据源目录）

本目录存放 `{{name}}` 功能的**数据源实现**，负责与外部环境（远程 API / 本地存储 / 设备能力等）直接交互。

## 职责

- 封装具体的外部读写细节：HTTP 请求（基于 `Dio`）、本地数据库、SharedPreferences、平台通道等。
- 将原始响应转换为本功能的数据模型（`../models` 中的 DTO），或在失败时抛出 `Exception`（框架不做归一化，由上层 BLoC 处理）。
- 只做"取数"，不包含业务规则、状态管理或 UI 逻辑。

## 存放内容

- 远程数据源：`{{name}}_remote_data_source.dart`（封装 Dio 调用）。
- 本地数据源：`{{name}}_local_data_source.dart`（封装本地持久化）。
- 可按来源分子目录（`remote/`、`local/`）进一步归类。
- 接口与实现分离：建议定义抽象类（如 `{{#pascalCase}}{{name}}{{/pascalCase}}RemoteDataSource`），便于在测试中用 mock 替换。

## 何时需要填充本目录

本目录**默认为空**，这是正常状态，不是漏写文件。是否需要在此建立数据源，取决于功能复杂度：

- **不需要（保持空目录）**：
  - 本功能只有一个远程接口、且 Repository 较薄（直接持 `Dio` 调用即可，如 `{{name}}` 生成的初始形态）；
  - 或团队约定跳过 fake / mock 数据源。

- **需要（在此建立数据源）**，出现以下任一情况：
  1. **后端未就绪**：先写抽象 `{{name}}_data_source.dart` + `{{name}}_fake_data_source.dart`，后端就绪后追加 `{{name}}_remote_data_source.dart` 并在 Module 中切换实现；
  2. **含本地存储**：写 `{{name}}_local_data_source.dart`（纯本地场景无需抽象接口与 fake）；
  3. **Repository 含编排逻辑**：如缓存优先 / 远程失败兜底本地 / 多源合并，需保留 Repository 真身、只替换 I/O。

> 提示：fake 接缝也可直接落在 **Repository 层**（实现 `Fake{{#pascalCase}}{{name}}{{/pascalCase}}Repository` 更简单），只有当需要测试 Repository 的编排逻辑时，才下沉到本目录。

## 约定

- 数据源仅被同层 `../repositories` 的仓储依赖；**不要**被 `bloc/` 或 `pages/` 直接引用（依赖方向：bloc → repository → data_source）。
- 跨功能复用的数据源应上移到 `core/data`，而非留在本目录。
- 不在本目录放业务逻辑判断，业务编排交给 repository。

## 最小示例（编写 / 注册 / 引用）

以「分页拉取用户列表」为例，演示「数据源 → 仓储」的完整链路。将示例中的 `User` 替换为你自己的业务模型即可。

### 1. 编写：定义抽象接口与实现

`{{name}}_user_data_source.dart`（与本 README 同目录）

```dart
// 抽象接口：只声明"能取什么数据"，不含实现
abstract class {{#pascalCase}}{{name}}{{/pascalCase}}UserDataSource {
  Future<List<UserDto>> fetchUsers({
    required int page,
    required int limit,
  });
}
```

`{{name}}_user_remote_data_source.dart`（与本 README 同目录）

```dart
// 远程实现：只负责调用 Dio、把原始响应转成 DTO
class {{#pascalCase}}{{name}}{{/pascalCase}}UserRemoteDataSource implements {{#pascalCase}}{{name}}{{/pascalCase}}UserDataSource {
  new(this._dio);

  final Dio _dio;

  @override
  Future<List<UserDto>> fetchUsers({required int page, required int limit}) async {
    final res = await _dio.get<List<dynamic>>(
      '/users',
      queryParameters: {'_page': page, '_limit': limit},
    );
    return (res.data ?? [])
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

> 后端未就绪时，加一个 `{{#pascalCase}}{{name}}{{/pascalCase}}UserFakeDataSource implements {{#pascalCase}}{{name}}{{/pascalCase}}UserDataSource`，
> 内部直接 `return [...]` 返回写死的 `UserDto` 列表即可，无需网络。

### 2. 注册：在 Module 中注入实现

`../{{name}}_module.dart`

```dart
static void register(GetIt getIt) {
  // 按环境切换：开发用 fake 顶替，后端就绪后换成 Remote
  // kDebugMode 来自 package:flutter/foundation.dart
  getIt.registerLazySingleton<{{#pascalCase}}{{name}}{{/pascalCase}}UserDataSource>(
    () => kDebugMode
        ? {{#pascalCase}}{{name}}{{/pascalCase}}UserFakeDataSource()
        : {{#pascalCase}}{{name}}{{/pascalCase}}UserRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>(
    () => {{#pascalCase}}{{name}}{{/pascalCase}}Repository(dio: getIt<Dio>(), userDataSource: getIt<{{#pascalCase}}{{name}}{{/pascalCase}}UserDataSource>()),
  );
}
```

### 3. 引用：仓储依赖数据源，只做映射

`../repositories/{{name}}_repository.dart`

```dart
class {{#pascalCase}}{{name}}{{/pascalCase}}Repository extends BaseRepository {

  new({required super.dio, required this.userDataSource});

  final {{#pascalCase}}{{name}}{{/pascalCase}}UserDataSource userDataSource;

  Future<({List<User> users, int total})> fetchUsers({
    required int page,
    required int limit,
  }) async {
    // 数据源返回 DTO，仓储负责转成领域实体 User
    final dtos = await userDataSource.fetchUsers(page: page, limit: limit);
    final users = dtos.map(User.fromJson).toList();
    return (users: users, total: users.length);
  }
}
```

> `UserDto` 是接口原始模型（放在 `../models`）；`User` 是 freezed 领域实体。
> 依赖方向：bloc → repository → data_source，data_source 不被上层直接引用。
