import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

void main() {
  test('rejects out-of-range column values before storage truncates them', () {
    final List<int> base = List<int>.filled(80, 0);
    expect(
      () => CardImage.fromColumns([...base]..[0] = 0x1000),
      throwsArgumentError,
    );
    expect(
      () => CardImage.fromColumns([...base]..[0] = 0x10000),
      throwsArgumentError,
    );
    expect(
      () => CardImage.fromColumns([...base]..[0] = -1),
      throwsArgumentError,
    );
    expect(
      () => CardImage.fromColumns([...base]..[0] = -65536),
      throwsArgumentError,
    );
  });

  test('rejects the wrong number of columns', () {
    expect(
      () => CardImage.fromColumns(List.filled(79, 0)),
      throwsArgumentError,
    );
    expect(
      () => CardImage.fromColumns(List.filled(81, 0)),
      throwsArgumentError,
    );
  });

  test('value equality and hashing', () {
    final a = CardImage.fromColumns(List<int>.generate(80, (int i) => i));
    final b = CardImage.fromColumns(List<int>.generate(80, (int i) => i));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(CardImage.blank()));
  });
}
