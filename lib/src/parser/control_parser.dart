/// The compile control-card parser (M2).
///
/// $CMPLE: deck.name in columns 8–13, then the option list — comma
/// separated, terminated by the first blank (J 02.01.01) — and the
/// secondary identifier in columns 55–72 (J 02.01.02). *COMPILE is the
/// attested 1961 spelling: the verb fills columns 7–14, options follow,
/// and no deck.name field exists (D7.12).
library;

import '../ast/control_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/source_card.dart';
import 'parser_messages.dart';

/// The documented option set (J 02.01.01).
const Set<String> compileOptions = {
  'NODECK', 'LIST', 'DICT', 'LOAD', 'LOGIC', 'FILES', 'MAP', 'NOGO', //
};

/// Parses the compile control [card], appending to [diagnostics];
/// `null` in, `null` out. [pedantic] adds message 923 when deck.name
/// contains imbedded blanks (decision D7.11; D11.4); the stored
/// [CompileCard.deckName] is unchanged in both modes.
CompileCard? parseCompileCard(
  SourceCard? card,
  List<Diagnostic> diagnostics, {
  bool pedantic = false,
}) {
  if (card == null) {
    return null;
  }
  final historical = card.textRange(1, 6) != r'$CMPLE';
  // Deck.name may start anywhere in its field, leading blanks ignored;
  // imbedded blanks are accepted silently (D7.11).
  final String deckName = historical ? '' : card.textRange(8, 13).trim();
  if (pedantic && deckName.contains(' ')) {
    // Leading blanks are ignored (J 02.01.01); a blank surviving the
    // trim of both ends is necessarily imbedded (D7.11). The detected
    // name is the same trimmed value stored above.
    diagnostics.reportAt(msgDeckNameImbeddedBlanks, card, operands: [deckName]);
  }
  final optionsFrom = historical ? 15 : 14;
  final options = <String>[];
  // "The options used must not be separated by blanks as the first
  // blank terminates the list of options. The options must be
  // separated only by commas." (J 02.01.01)
  final String field = card.textRange(optionsFrom, 54);
  final String afterLead = field.trimLeft();
  final int blank = afterLead.indexOf(' ');
  final String list = blank < 0 ? afterLead : afterLead.substring(0, blank);
  for (final String option in list.split(',')) {
    if (option.isEmpty) {
      continue;
    }
    options.add(option);
    if (!compileOptions.contains(option)) {
      diagnostics.reportAt(msgUnknownCompileOption, card, operands: [option]);
    }
  }
  return CompileCard(
    card: card,
    historicalSpelling: historical,
    deckName: deckName,
    options: options,
    secondaryIdentifier: card.textRange(55, 72).trimRight(),
  );
}
