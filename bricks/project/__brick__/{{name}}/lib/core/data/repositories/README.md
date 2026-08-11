# 共享仓库（Shares Repositories）

当某个 Repository 被 **2 个及以上 feature** 共用时，把它放到本目录
（`lib/core/data/repositories/`），再到 `lib/core/data/shares_repositories.dart`
的 `register` 中登记为 `lazySingleton`。

## 约定

- **源码位置**：本目录（如 `user_repository.dart`）。
- **DI 注册**：在 `SharesRepositories.register(GetIt)` 中登记。
  `SharesRepositories.register(getIt)` 已在 `InjectionBase.registerFeatureModules`
  （`lib/core/di/injection_base.dart`）中调用，启动即生效。
- **取用**：调用方通过 `getIt<XxxRepository>()` 获取，无需互相 import feature。

## 与 feature 自有仓库的区别

- feature 自有仓库：放在 `features/<name>/data/repositories/`，由各自的
  `<Name>Module.register(getIt)` 注册。
- 跨 feature 共享仓库：放在本目录，由 `SharesRepositories` 集中注册。
