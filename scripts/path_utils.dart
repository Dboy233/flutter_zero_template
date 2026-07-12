// ignore_for_file: unused_element

/// 将相对路径 relative 解析到 base（绝对目录）下，并正确折叠 ".." / "."。
String resolve(String base, String relative) {
  final rel = normalize(relative);
  final target = rel.startsWith('/') || isAbsDrive(rel)
      ? rel
      : join(base, rel);
  return normalizeDots(target);
}

/// 折叠路径中的 "." 与 ".."，保留绝对路径的前导 "/" 或盘符。
String normalizeDots(String p) {
  final isAbs = p.startsWith('/') || isAbsDrive(p);
  final drive = isAbsDrive(p) ? p.substring(0, 2) : '';
  final body = drive.isNotEmpty
      ? p.substring(2)
      : (p.startsWith('/') ? p.substring(1) : p);
  final stack = <String>[];
  for (final seg in body.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (stack.isNotEmpty && stack.last != '..') {
        stack.removeLast();
      } else if (!isAbs) {
        stack.add('..');
      }
      // 绝对路径的 ".." 到达根后不再上移
    } else {
      stack.add(seg);
    }
  }
  final joined = stack.join('/');
  if (isAbs) {
    if (drive.isNotEmpty) return '$drive/$joined';
    return '/$joined';
  }
  return joined.isEmpty ? '.' : joined;
}

bool isAbsDrive(String p) => RegExp(r'^[a-zA-Z]:').hasMatch(p);

String normalize(String p) => p.replaceAll('\\', '/');

String basename(String p) {
  p = normalize(p);
  final idx = p.lastIndexOf('/');
  return idx < 0 ? p : p.substring(idx + 1);
}

String dirname(String p) {
  p = normalize(p);
  final idx = p.lastIndexOf('/');
  return idx < 0 ? '.' : p.substring(0, idx);
}

String extension(String p) {
  final base = basename(p);
  final idx = base.lastIndexOf('.');
  if (idx <= 0) return ''; // 无扩展名，或为点文件（如 .gitignore）
  return base.substring(idx); // 含点，如 ".dart"
}

String join(String a, String b) {
  a = normalize(a);
  b = normalize(b);
  if (a.isEmpty) return b;
  if (a.endsWith('/')) return '$a$b';
  return '$a/$b';
}

bool isExcluded(String name, String ext, List<String> exclude) {
  for (final e in exclude) {
    final ne = normalize(e);
    if (ne == name) return true; // 文件夹/文件名完全匹配
    if (ne == ext) return true; // 后缀（含点），如 ".dart"
    if (ext.isNotEmpty && ne == ext.substring(1)) {
      return true; // 后缀（无点），如 "dart"
    }
  }
  return false;
}

/// 计算 path 相对于 from 的相对路径（两者已规范化、同盘符）。
/// 仅用于 replace 目录与输出目录同仓库前缀一致的情形。
String relative(String path, String from) {
  path = normalize(path);
  from = normalize(from);
  if (from.endsWith('/')) from = from.substring(0, from.length - 1);
  if (path == from) return '.';
  if (path.startsWith('$from/')) return path.substring(from.length + 1);
  // 前缀不一致时退回绝对路径（本场景不会出现）
  return path;
}
