/// 一次性 UI 副作用开放基类。
///
/// BLoC 通过 [emitEffect] 发出副作用，由 UI 层 [EffectListener] 消费并执行。
///
/// 基类是 **开放** 的（[abstract] 而非 [sealed]）：任何库都能直接
/// `extends UIEffect` 添加自定义副作用类型，无需修改本文件，也无需同库声明。
/// 责任链中的处理器通过 `is` 检查认领自己关心的类型，互不干扰。
///
/// One-time UI side effect open base class.
///
/// BLoCs emit effects via [emitEffect]; the UI layer consumes them via
/// [EffectListener] and executes them.
///
/// The base class is **open** (abstract, not sealed): any library can
/// `extends UIEffect` to add a custom effect type without editing this file
/// or declaring the subclass in the same library. Chain handlers claim only
/// the types they care about via `is` checks, so they never interfere.
abstract class UIEffect {
  const UIEffect();
}

/// Toast 提示副作用。
///
/// 本类不强制依赖任何国际化框架。[message] 可直接用于显示固定文本；
/// [messageCode] 可用于 gen-l10n、slang、easy_localization 等任意方案，
/// 由 UI 层（框架默认处理器或业务自定义处理器）自行决定如何解析。
/// 也可以同时提供两者，让 UI 层优先使用 [message]。
///
/// Toast message effect.
///
/// This class does not depend on any internationalization framework. Use [message]
/// for fixed text, or [messageCode] for any i18n key (gen-l10n, slang,
/// easy_localization, etc.), resolved by the UI layer (the framework default
/// handler or a business-specific handler). Both may be supplied; the UI layer
/// prefers [message] when present.
final class ToastEffect extends UIEffect {
  const ToastEffect({
    this.message,
    this.messageCode,
    this.extra,
  });

  /// 可直接显示的文本。
  ///
  /// Fixed text to display directly.
  final String? message;

  /// 消息标识，由 UI 层根据项目的国际化方案解析。
  ///
  /// Message code resolved by the UI layer according to the project's i18n setup.
  final String? messageCode;

  /// 额外参数。
  /// Extra arguments.
  final Object? extra;
}

/// 对话框副作用。
///
/// 本类只携带业务类型标识 [type] 和可选的 [extra]。具体的标题、内容、
/// 按钮样式等 UI 细节由 UI 层（业务自定义处理器）根据 [type] 自行决定。
///
/// 框架同时提供 [defaultDialogHandle] 作为兜底：它只为未被业务 handle 认领的
/// [DialogEffect] 渲染一个最小通用对话框，避免副作用被静默丢弃；真正符合
/// 产品需求的对话框应由业务 handle 渲染。
///
/// Dialog effect.
///
/// This class only carries a business [type] and optional [extra]. The actual
/// title, content, button styles, etc. are decided by the UI layer (a
/// business-specific handler) based on [type].
///
/// The framework also ships [defaultDialogHandle] as a fallback: it renders a
/// minimal generic dialog only for [DialogEffect]s not claimed by a business
/// handler, so effects are never silently dropped; the real, product-specific
/// dialog should be rendered by a business handler.
final class DialogEffect extends UIEffect {
  const DialogEffect({
    required this.type,
    this.extra,
  });

  /// 对话框业务类型标识，例如 `retry`、`refresh_success`。
  ///
  /// Business type identifier, e.g. `retry`, `refresh_success`.
  final String type;

  /// 额外参数，可用于传递标题、内容、回调标识等。
  ///
  /// Extra arguments, such as title, content, or callback identifiers.
  final Object? extra;
}

/// 加载指示器副作用（通用 loading）。
///
/// 框架默认处理器 [defaultLoadingHandle] 会拦截该类型并调用注入的
/// [LoadingService]，因此业务层只需
/// `emitEffect(const LoadingEffect(show: true))` 即可控制全局 loading，
/// 无需关心具体实现框架。
///
/// 通用 loading 仅表达“显示/隐藏”意图；若需携带状态文案，可通过 [extra]
/// （应为 [String]）传递，框架默认处理器会透传给 [LoadingService.show]。
///
/// Loading indicator effect (generic loading).
///
/// The framework default handler [defaultLoadingHandle] intercepts this type
/// and delegates to the injected [LoadingService], so the business layer only
/// needs `emitEffect(const LoadingEffect(show: true))` to control global
/// loading without knowing the concrete implementation.
///
/// The generic loading only expresses show/hide intent. To attach a status
/// string, pass it via [extra] (must be a [String]); the default handler
/// forwards it to [LoadingService.show].
final class LoadingEffect extends UIEffect {
  const LoadingEffect({required this.show, this.extra});

  /// 为 `true` 显示加载指示器，`false` 隐藏。
  /// `true` shows the indicator, `false` hides it.
  final bool show;

  /// 可选的状态文案（应为 [String]），由框架默认处理器透传给 [LoadingService.show]。
  /// Optional status text (should be a [String]), forwarded to
  /// [LoadingService.show] by the default handler.
  final Object? extra;
}

// 扩展 Effect 类型：
// 1. 在任意库新建 `class XxxEffect extends UIEffect { ... }`
// 2. 若该类型是通用意图（如 loading），由框架默认处理器
//    [defaultLoadingHandle] 统一处理；若要替换底层实现，只需在 DI 中替换
//    [LoadingService] 的注册，处理器本身无需改动。
// 3. 若是业务类型（如弹窗），在你自己的 handle 函数（参考 [homeEffectHandle]）
//    中用 `is` 检查认领，并把该函数传入 [EffectListener.effectsHandles]；
//    返回 `true` 表示已处理（责任链命中即止），`false` 表示交给后续处理器。
// 4. 在 BLoC 中通过 `emitEffect(XxxEffect(...))` 发出新的副作用
//    （经 [BlocEffectMixin.effectStream]）。
// 5. 不需要修改 [BlocEffectMixin] 或 [EffectListener]。
//
// To extend the effect type:
// 1. Create `class XxxEffect extends UIEffect { ... }` in any library.
// 2. For generic intents (e.g. loading), the framework default handler
//    [defaultLoadingHandle] handles them uniformly; to swap the underlying
//    implementation, just replace the [LoadingService] registration in DI.
// 3. For business types (e.g. dialog), claim it in your own handle function
//    (see [homeEffectHandle]) via an `is` check and pass that function to
//    [EffectListener.effectsHandles]. Return `true` to signal "handled"
//    (chain stops on first match), `false` to let subsequent handlers run.
// 4. Emit the new effect in a BLoC via `emitEffect(XxxEffect(...))`
//    (through [BlocEffectMixin.effectStream]).
// 5. [BlocEffectMixin] and [EffectListener] do not need to be changed.
