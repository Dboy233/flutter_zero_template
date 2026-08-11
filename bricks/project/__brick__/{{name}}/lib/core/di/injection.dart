import 'package:shared_preferences/shared_preferences.dart';

import '../auth/token_storage.dart';
import '../localization/locale_provider.dart';
import '../notifiers/desktop_toast_service.dart';
import '../notifiers/implementers/easyloading_service.dart';
import '../notifiers/implementers/easyloading_toast_service.dart';
import '../notifiers/implementers/toastification_service.dart';
import '../notifiers/loading_service.dart';
import '../notifiers/toast_service.dart';
import '../storage/secure_storage_service.dart';
import '../storage/shared_preferences_storage_service.dart';
import '../storage/storage_service.dart';
import '../theme/theme_provider.dart';
import 'get_it_instance.dart';
import 'injection_base.dart';

export 'get_it_instance.dart';

/// 用户可修改的 DI 子类，负责注册基础设施。
///
/// 继承 [InjectionBase] 并实现 [registerBaseDependencies] 与
/// [registerUserDependencies]。父类已定义好注册顺序并自动维护
/// Feature Modules 的注册区域。
///
/// 网络层（[Dio]）不在本类中注册 —— 由各环境的 main 函数
/// 在 [registerAll] 之后手动注册，以便传入不同的 baseUrl。
///
/// User-editable DI subclass, responsible for infrastructure registration.
///
/// Extends [InjectionBase] and implements [registerBaseDependencies] and
/// [registerUserDependencies]. The base class defines the registration order
/// and automatically maintains the Feature Modules registration area.
///
/// The network layer ([Dio]) is NOT registered here — each environment's
/// main function registers it manually after [registerAll] to pass a different
/// baseUrl.
class Injection extends InjectionBase {
  @override
  Future<void> registerBaseDependencies() async {
    await _registerStorageLayer();
    await _registerAuthLayer();
    _registerNotifiersLayer();
    await _registerLocalizationLayer();
    await _registerThemeLayer();
  }

  @override
  Future<void> registerUserDependencies() async {
    // 在此添加自定义依赖 / 第三方 SDK。
    // Add custom dependencies or third-party SDKs here.
  }

  // ── 存储层 ──────────────────────────────────────────────────

  Future<void> _registerStorageLayer() async {
    final prefs = await SharedPreferences.getInstance();
    getIt
      ..registerLazySingleton<StorageService>(
        () => SharedPreferencesStorageService(prefs),
      )
      ..registerLazySingleton<SecureStorageService>(SecureStorageService.new);
  }

  // ── Auth 层 ─────────────────────────────────────────────────

  Future<void> _registerAuthLayer() async {
    final tokenStorage = TokenStorage(
      secureStorage: getIt<SecureStorageService>(),
    );
    await tokenStorage.init();
    getIt.registerSingleton<TokenStorage>(tokenStorage);
  }

  // ── Notifiers 层 ────────────────────────────────────────────

  void _registerNotifiersLayer() {
    getIt
      ..registerLazySingleton<ToastService>(EasyLoadingToastService.new)
      ..registerLazySingleton<DeskTopToastService>(
        ToastificationToastService.new,
      )
      ..registerLazySingleton<LoadingService>(EasyLoadingLoadingService.new);
  }

  // ── 国际化层 ────────────────────────────────────────────────

  Future<void> _registerLocalizationLayer() async {
    final localeProvider = LocaleProvider(storage: getIt<StorageService>());
    await localeProvider.restoreFromStorage();
    getIt.registerSingleton<LocaleProvider>(localeProvider);
  }

  // ── 主题层 ─────────────────────────────────────────────────

  Future<void> _registerThemeLayer() async {
    final themeProvider = ThemeProvider(storage: getIt<StorageService>());
    await themeProvider.restoreFromStorage();
    getIt.registerSingleton<ThemeProvider>(themeProvider);
  }
}
