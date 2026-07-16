import 'package:get_it/get_it.dart';

/// 共享仓库的 DI 注册中心。
///
/// 当某个 Repository 被 2 个及以上 feature 共用时，把源码放在
/// `core/data/repositories/`，并在下方的 [register] 中注册为 `lazySingleton`。
/// [register] 由 [InjectionBase] 的 `registerFeatureModules`（位于 `injection_base.dart`）
/// 调用，与 feature 模块注册一起在启动时生效，无需在别处再次调用。
///
/// 用法：
/// 1. 把共享仓库源码放在 `core/data/repositories/`；
/// 2. 在下方 [register] 中注册为 `lazySingleton`；
/// 3. 调用方通过 `getIt<XxxRepository>()` 取用，无需互相 import feature。
///
/// Shared repository DI registration hub.
///
/// [register] is invoked from [InjectionBase.registerFeatureModules] (in
/// `injection_base.dart`); add your shared repositories below.
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
