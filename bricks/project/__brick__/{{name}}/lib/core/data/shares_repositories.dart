import 'package:get_it/get_it.dart';

/// 共享仓库的 DI 注册中心。
///
/// 当某个 Repository 被 2 个及以上 feature 共用时，**不要**把它注册进
/// [InjectionBase] 的 `registerFeatureModules`（那是 `fluzer new` 自动维护的
/// 区域），也**不要**改 `injection_base.dart` 的代码。统一在此登记即可。
///
/// 用法：
/// 1. 把共享仓库源码放在 `core/data/repositories/`；
/// 2. 在下方 [register] 中注册为 `lazySingleton`；
/// 3. 调用方通过 `getIt<XxxRepository>()` 取用，无需互相 import feature。
///
/// 本文件的 [register] 由用户子类 `injection.dart` 的 `registerUserDependencies`
/// 调用，框架基类 `injection_base.dart` 保持不动。
///
/// Shared repository DI registration hub.
///
/// Register cross-feature shared repositories here instead of touching the
/// auto-maintained [InjectionBase] / `injection_base.dart`.
class SharesRepositories {
  /// 注册所有共享仓库。
  ///
  /// Registers all shared repositories.
  static void register(GetIt getIt) {
    // 示例：取消注释即可启用（user_repository.dart 放在本目录）。
    // Example: uncomment to enable (user_repository.dart lives in this folder).
    // getIt.registerLazySingleton<UserRepository>(
    //   () => UserRepository(client: getIt<DioClient>()),
    // );
  }
}
