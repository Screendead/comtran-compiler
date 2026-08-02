import 'package:comtran/comtran.dart';

void main(List<String> args) {
  if (args.contains('--version')) {
    print('comtranc $comtranVersion');
    return;
  }
  print(
    'comtranc $comtranVersion — COMTRAN (Commercial Translator) '
    'compiler reconstruction.',
  );
  print(
    'No compiler passes exist yet (M0 in progress). '
    'Roadmap: docs/HANDOVER.md; decisions: docs/design/decisions.md.',
  );
}
