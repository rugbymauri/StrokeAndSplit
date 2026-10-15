import 'package:aergrow/app/platform_providers.dart';

/// Keeps "saved" files in memory and hands out [toOpen] when a file is picked.
class FakeSessionFiles implements SessionFiles {
  final saved = <String, List<int>>{};
  List<int>? toOpen;

  @override
  Future<bool> save(String fileName, List<int> bytes) async {
    saved[fileName] = bytes;
    return true;
  }

  @override
  Future<List<int>?> open() async => toOpen;
}
