# Changelog

本文件记录 `flutter_zero_template` 的所有重要变更。格式参考 [Keep a Changelog](https://keepachangelog.com/)。

> 模板版本与 CLI 版本独立发布、互不绑定；二者之间的版本约束关系见文档「版本约束规则」（`flutter_zero_doc/docs/zh/versioning-rules.md`）。

## [4.0.1] - 2026-09-13

### Added
- 三份 feature 系列 brick（`feature` / `feature_bloc` / `feature_cubit`）的 `data_sources/README.md` 新增「何时需要填充本目录」与「最小示例（编写 / 注册 / 引用）」两节：明确空目录是正常占位而非漏写、给出三类触发条件（后端未就绪 / 含本地存储 / Repository 含编排逻辑），并以中性的「分页拉取用户列表」演示「数据源 → 仓储」完整链路（抽象接口 + 远程实现 + Module 按 `kDebugMode` 切换 + Repository 映射），降低新手上手门槛。
- `template_registry.json` 新增 `4.0.1` 条目，供 `fluzer` 拉取新版模板。

### Changed
- 修复三份 feature 砖 `data_sources/README.md` 中类名占位符 `{{Name}}` 的渲染 bug。

## [4.0.0] - 2026-09-09

### Added
- `template_registry.json` 新增 `4.0.0` 条目，供 `fluzer` 拉取新版模板。
- `project` brick 的 `pubspec.yaml` 新增 `dependency_overrides` 注释模板与 `assets` / `fonts` 注释模板，便于按需启用。

### Changed
- **核心操作等待机制对齐**：`lib/core/bloc/bloc_await_mixin.dart` 整体重构为「事件即身份 + `AwaitResolution<T>` 密封类」架构（与 3.0.0 文档描述的语义一致）。`runAwait<E>(event)` 返回 `Future<AwaitResolution<State>>`，等待结局由 `AwaitCompleted` / `AwaitErrored` / `AwaitDropped` / `AwaitCancelled` 密封子类表征，调用端以 `switch` / `is` 收窄判断，不再依赖异常。
- **Dart 3.13 主构造语法迁移**：`project` 与三个 feature 系列 brick（`feature` / `feature_bloc` / `feature_cubit`）中所有默认构造函数改为 `new` 主构造写法（BLoC / Cubit / Page / Body / Repository / Module / App 根组件等）。
- **模板状态与模块骨架调整**：feature 系列 brick 的 freezed 状态默认工厂改为 `const factory() = _XxxState;` 形式；模块私有构造函数由 `XxxModule._()` 改为 `new _()`，与 `flutter_zero_app` 验证项目保持一致。
- **依赖与 SDK 升级**：`pubspec.yaml` 的 SDK 最低版本 `^3.12.2` → `^3.13.0`；`freezed` `^3.2.5` → `^4.0.1`、`very_good_analysis` `^10.3.0` → `^11.0.0`、`flutter_secure_storage` `^10.3.1` → `^11.0.0`、`flutter_easyloading` `^3.0.5` → `^4.0.2`、`go_router` `^17.3.0` → `^18.0.1`；新增显式 `bloc`、`test` 依赖；`pubspec` 依赖按层分组并补充分组注释。
- **静态分析调整**：`analysis_options.yaml` 新增 `sort_pub_dependencies: ignore`（依赖按层分组、非字母序）。
- **核心模块同步**：`effect` / `result` / `notifiers` / `theme` / `network` / `storage` 等核心实现同步至最新版本并采用 Dart 3.13 写法。
- `fluzer.yaml` 模板版本号 `3.0.0` → `4.0.0`。

## [3.1.0] - 2026-08-30

### Added
- 新增 `feature_bloc` Mason brick，生成基于 BLoC（事件 + 状态）的 MVI 功能模块骨架，与原 `feature` brick 目录结构一致。
- 新增 `feature_cubit` Mason brick，生成基于 Cubit 的 MVVM 功能模块骨架（以 `presentation/cubit/` 取代 `presentation/bloc/`，无事件、直接调用方法）。

### Changed
- `feature` brick 页面重构：`{{name}}_page.dart` 与 `{{name}}_body.dart` 改为 `part of` 关联，`_Body` 设为私有类，统一三个 feature 系列 brick 的代码组织风格。
- `project` brick 的 `pubspec.yaml` 新增 `easy_refresh: ^3.5.1` 依赖，使生成项目开箱即可使用下拉刷新 / 上滑加载骨架。

## [3.0.0] - 2026-08-29

### Changed
- `lib/core/bloc/bloc_await_mixin.dart` 操作等待机制重构为「事件即身份」模式，等待标识由手写字符串改为事件本身，传错标识从运行时超时提前为编译期错误。
- 相同事件处于进行中时自动合并等待、不再重复发送事件（重复的下拉刷新、重复点击只会执行一次操作）；参数不同的事件各自独立执行、互不干扰。
- 等待超时改为只对单个等待方生效：某个调用方超时不再影响同事件下其他等待方，超时的等待也会被即时清理，不再驻留内存。
- 页面（BLoC）关闭时所有未完成的等待以正常方式结束，不再向调用方抛出异常，避免下拉刷新后立即退出页面时报错。

### Removed
- 等待触发的 `key` 参数与事件处理器的并发策略透传参数均已移除，等待 API 收敛为「等待事件、注册事件处理器、手动完成」三个入口。从 2.0.0 创建的项目升级时，需将手写的字符串等待标识调用改为传入事件本身。

## [2.0.0] - 2026-08-19

### Added
- 新增 `fluzer.yaml`，作为原 `flutter_zero_config.yaml` 的更名文件（详见 Removed），结构精简为仅保留 `version` 与 `template_name`。
- `BaseRepository` 从 `core/storage` 迁移至 `core/network`，并极简化为仅持有 `Dio` 实例，不再提供任何响应解析与异常处理助手，将决定权交还开发者。
- 新增 `lib/core/network/interceptors/` 子目录，将原根目录下的 `auth_interceptor.dart` 与 `locale_interceptor.dart` 归入其中。
- 新增 `lib/core/network/test_repository.dart` 示例仓储，演示 `mixin XxxRepositoryMixin on BaseRepository` + 私有请求方法 + 公开业务方法的零封装仓储编写范式。
- 新增多环境入口 `main_dev.dart`（开发）与 `main_staging.dart`（测试），各环境 baseUrl 独立配置，配合 `flutter run -t lib/main_dev.dart` 切换。
- feature brick 新增 `data/models/README.md`，取代原先生成的示例 Model 文件，仅说明模型约定。

### Changed
- `main.dart` 改为手动注册 `Dio` 单例（注入 `AuthInterceptor` / `LocaleInterceptor`），不再依赖被移除的 `DioClient`；并补充多环境入口切换说明。
- 依赖注入 `core/di/injection.dart` 删除 `_registerNetworkLayer()`（原注册 `DioClient`），改为由各环境 `main` 手动注册 `Dio`。
- `core/result/result.dart`：`Failure.exception` 字段类型由 `AppException` 改为 `Exception`；`runToResult` 重命名为 `runCatching`。
- `core/effect/ui_effect.dart`：`ExceptionToToast` 扩展作用对象由 `AppException` 改为 `Exception`；`ToastEffect.code` 注释移除 `AppErrorCodes` 引用。
- `core/effect/effect_handle/default_toast_effect_handle.dart`：移除整段基于 `error400~504` 与解析错误的 `_handleErrorCode` 映射逻辑；Toast 文案解析优先级统一为 `message → l10nCode → code → Unknown`，兜底走 `l.unknownError(code)`。
- `core/bloc/bloc_error_handler_mixin.dart`：移除 `ErrorHandler` / `handleError` / `runWithErrorHandling`；`runCatching` 内部异常包装改为 `e is Exception ? Failure(e) : Failure(Exception(...))`；示例 `runToResult` 改为 `runCatching`。
- `core/bloc/bloc_cancel_token_mixin.dart`：示例异常处理写法同步更新为 `e is Exception ? e : Exception(...)`。
- `core/data/shares_repositories.dart`：示例由 `getIt<DioClient>()` 改为 `getIt<Dio>()`。
- `core/data/repositories/README.md` 与 `core/data/models/README.md`：示例/说明同步移除 `DioClient`、`parseList` / `parseSingle` 引用，改用 `super.dio`。
- feature brick `{{name}}_module.dart`：仓储注册由 `getIt<DioClient>()` 改为 `getIt<Dio>()`。
- feature brick `{{name}}_repository.dart`：`BaseRepository` 导入路径由 `core/storage` 改为 `core/network`；`super.client` 改为 `super.dio`，并移除附带的示例方法（由 README 取代）。
- `lib/l10n/app_zh.arb` / `app_en.arb`：大幅精简错误码文案，移除 `error400~504`、`parseError`、`noConnection`、`requestTimeout` 等 20+ 条，仅保留 `unknownError`。

### Removed
- 删除整套异常体系：`core/error/app_exception.dart`（`AppException` 及 `ServerException` / `ParseException` 等子类）、`core/error/error_handler.dart`、`core/error/app_error_codes.dart`、`core/error/server_message_extractor.dart`。框架改为零异常封装，网络异常原样外抛，由 BLoC 经 `Exception → ToastEffect` 上报。
- 删除 `core/network/dio_client.dart`：`DioClient` 封装类（含 `get/post/put/delete/uploadFile`），改由开发者直接使用 `dio` 实例。
- 删除 `core/constants/api_constants.dart`：`ApiConstants.baseUrl`，baseUrl 改由各环境 `main` 自行配置。
- 删除 feature brick 生成时附带的示例 `{{name}}_model.dart`。
- 删除 `flutter_zero_config.yaml`，由 `fluzer.yaml` 取代（详见 Added）。

## [1.0.1] - 2026-08-01

### Added
- `flutter_zero_config.yaml` 新增 `minCliVersion` 字段（当前为 `"1.1.0"`）。该字段声明此模板版本所依赖的最低 CLI 版本，供 `fluzer new` 与 `fluzer gen-l10n` 的版本门禁逻辑消费，用于判定当前 CLI 是否支持本项目模板。

### Changed
- 更新 `lib/core/effect/effect_handle/default_toast_effect_handle.dart` 的文档注释：当 `ToastEffect.l10nCode` 未被默认处理器处理时，说明可运行 `fluzer gen-l10n` 自动生成 `L10nCode` 值对象、`L10nToastType` 扩展与 `L10nToastEffectHelper`，将 `l10nCode` 映射为本地化文案并在业务 handle 中展示。
- 因文档引用了 `fluzer gen-l10n` 命令（由 CLI 1.1.0 引入），本模板版本的 `minCliVersion` 相应提升至 `1.1.0`。

## [1.0.0]

> 首个发布版本（初始日期未在仓库中记录）。

### Added
- `flutter_zero` 模板首个发布版本，包含 `project` 与 `feature` 两类 Mason brick，提供 MVI-BLoC 架构骨架、Effect 系统、依赖注入与示例。
