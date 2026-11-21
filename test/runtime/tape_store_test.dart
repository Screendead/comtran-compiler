/// The in-memory tape store the website runs over (roadmap W4). It must
/// answer as `DirectoryTapes` answers, so a run cannot tell the two
/// apart.
library;

import 'package:comtran/comtran_io.dart';
import 'package:test/test.dart';

import 'runtime_support.dart';

void main() {
  for (final (String name, TapeStore Function() store) in [
    ('MemoryTapes', MemoryTapes.new),
    ('DirectoryTapes', () => DirectoryTapes(tempDirectory('comtran-tapes'))),
  ]) {
    group(name, () {
      test('holds no image on a unit nothing wrote', () {
        expect(store().read('D1'), isNull);
      });

      test('an append to a unit with no image starts one', () {
        final TapeStore tapes = store()..append('C1', <int>[1, 2]);
        expect(tapes.read('C1'), <int>[1, 2]);
      });

      test('a write replaces the image, and an append extends it', () {
        final TapeStore tapes = store()
          ..write('C1', <int>[1, 2])
          ..write('C1', <int>[3])
          ..append('C1', <int>[4]);
        expect(tapes.read('C1'), <int>[3, 4]);
      });
    });
  }

  test('MemoryTapes copies the images it starts with', () {
    final image = <int>[1];
    final tapes = MemoryTapes(<String, List<int>>{'D1': image})
      ..append('D1', <int>[2]);
    expect(image, <int>[1]);
    expect(tapes.read('D1'), <int>[1, 2]);
  });

  test('MemoryTapes names a unit by its image file', () {
    expect(MemoryTapes().where('C2'), 'C2.tap');
  });
}
