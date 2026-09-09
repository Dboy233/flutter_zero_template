part of '{{name}}_page.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 页面内容区域。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} page body.
class _{{#pascalCase}}{{name}}{{/pascalCase}}Body extends StatelessWidget {
  /// 创建页面内容。
  ///
  /// Creates the page body.
  const new();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('{{#pascalCase}}{{name}}{{/pascalCase}}'),
      ),
    );
  }
}
