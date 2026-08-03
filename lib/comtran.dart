/// COMTRAN (Commercial Translator) — compiler reconstruction.
///
/// Reconstructs the January 1962 709/7090 field-test compiler documented by
/// F28-8043 and J28-6169 (`comtran-manuals/`). All design decisions live in
/// `docs/design/decisions.md`; the language reference is
/// `docs/comtran-language-definition.md`.
///
/// Planned module map (one directory per subsystem under `lib/src/`, added at
/// the milestone that first needs it — see the roadmap in `docs/HANDOVER.md`):
///
/// - `cards/`   — punch-level card images, BCD read-out, deck container,
///                text-mirror conversion (M1; format decision D0.5).
/// - `chars/`   — 6-bit BCD character set, card codes, both collating
///                sequences (M1; D0.6).
/// - `lexer/`   — column model, words, literals, continuation (M1).
/// - `listing/` — the compilation listing, the first observable output (M1).
/// - `parser/`  — three divisions plus control cards, statement numbering,
///                diagnostics per the J 90.04 message catalog (M2).
/// - `data/`    — Data Description semantics and storage mapping (M3).
/// - `codegen/` — 7090 code generation in the 1962 listing's shapes (M4).
/// - `loader/`  — object decks (J 90.03) and the CT Loader (M4).
/// - `emulator/`— word-exact 36-bit 7090 CPU core (M4).
/// - `runtime/` — high-level-emulated SYS)/IOC) library, IOCS tape model
///                (M4–M5; D0.3, D0.7).
library;

export 'src/cards/canon_codec.dart';
export 'src/cards/card_image.dart';
export 'src/cards/text_codec.dart';
export 'src/chars/char_code.dart';
export 'src/lexer/diagnostic.dart';
export 'src/lexer/messages.dart';
export 'src/lexer/procedure_lexer.dart';
export 'src/lexer/severities.dart';
export 'src/lexer/source_card.dart';
export 'src/lexer/source_program.dart';
export 'src/lexer/token.dart';
export 'src/version.dart';
