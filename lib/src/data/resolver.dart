/// The name resolver (M3 stage 2): the dictionary build, the CALL
/// pass, and reference resolution over the procedure division.
///
/// The triage and every site reading follow design notes M3-17 to
/// M3-21 (`docs/design/m3-data.md`). The pipeline order is M3-17's:
/// the dictionary and the CALL pass run before the environment binder,
/// because CALL exists to give the Environment Description one-word
/// names (J 02.03.02).
library;

import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../ast/procedure_ast.dart';
import '../lexer/diagnostic.dart';
import '../lexer/messages.dart';
import '../lexer/reserved_words.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import 'data_map.dart';
import 'data_messages.dart';
import 'dictionary.dart';
import 'images.dart';
import 'mapper.dart';
import 'pictorial.dart';
import 'subscripts.dart';

/// Builds the dictionary and resolves every name of one job.
final class NameResolver extends ClauseWalk {
  NameResolver(
    super.diagnostics,
    this.mapper, {
    this.pedantic = false,
    this.tableLimits = true,
  });

  final DataMapper mapper;
  final bool pedantic;

  /// False under `--no-table-limits` (D9.7): the capacity counters
  /// stay silent.
  final bool tableLimits;

  /// The job's dictionary (M3-8; M3-17).
  final Dictionary dictionary = Dictionary();

  /// Every resolved data reference, identity-keyed — M4 generates code
  /// from these.
  final Map<NameReference, DataItem> dataResolutions = Map.identity();

  /// Condition references that resolve to an Environment COND card —
  /// the console-key test (J 02.06.17).
  final Set<NameReference> keysConditions = Set.identity();

  late final SubscriptChecker _subscripts = SubscriptChecker(
    mapper,
    dataResolutions,
    report,
    tableLimits: tableLimits,
  );

  /// Set while the triage runs over a subscript expression. A condition
  /// name resolves there, so that M3-20's msg 71 speaks for it in place
  /// of the triage's msg 25 (M3-17: a site-specific row overrides).
  bool _inSubscript = false;

  /// List-3 words an environment card of the job uses (M2-7; M3-17).
  final Set<String> _usedListThree = {};

  /// Environment COND card names — console-key conditions.
  final Set<String> _keysConditionNames = {};

  // ── The dictionary (M3-17) ───────────────────────────────────────

  /// Enters every declared name. [dataGroups] carries the *DATA
  /// portion boundaries for the msg 197 precedence check.
  void buildDictionary(
    List<List<DataItem>> dataGroups,
    List<EnvironmentCard> environmentCards,
    List<List<Sentence>> procedureGroups,
  ) {
    dataGroups.forEach(_enterDataPortion);
    for (final card in environmentCards) {
      for (final Token token in card.spec.optionTokens) {
        if (keyWordClassOf(token.text) == KeyWordClass.environmentConditional) {
          _usedListThree.add(token.text);
        }
      }
      final String name = card.spec.name;
      if (name.isEmpty) {
        continue;
      }
      final SourceCard anchor = card.spec.cards.first;
      if (card is CondCard) {
        _keysConditionNames.add(name);
        _enter(name, NameKind.condition, anchor);
      } else {
        if (name == programStartName) {
          // PROGRAM.START may only label a statement or section (D2.1).
          diagnostics.reportAt(msgProgramStartMisdeclared, anchor, column: 7);
        }
        _enter(name, NameKind.environment, anchor);
      }
    }
    procedureGroups.forEach(_enterProcedureNames);
    _checkListThreeShadows();
  }

  void _enterDataPortion(List<DataItem> portion) {
    // The precedence check (msg 197, M3-17): a RECORD entry after a
    // higher-numbered top-level entry reads as description punched
    // before its record name.
    var leadingLevel = -1;
    for (final item in portion) {
      if (item.parent == null) {
        final int? level = item.entry.level;
        if (item.typeCode == DataTypeCode.record) {
          if (level != null && leadingLevel > level) {
            diagnostics.reportAt(
              msgRecordNameMustPrecede,
              item.entry.cards.first,
              column: 7,
            );
          }
        } else if (level != null && level > leadingLevel) {
          leadingLevel = level;
        }
      }
      final String name = item.entry.name;
      if (name.isEmpty || item.nameDiscarded) {
        continue;
      }
      final SourceCard anchor = item.entry.cards.first;
      if (name == programStartName) {
        diagnostics.reportAt(msgProgramStartMisdeclared, anchor, column: 7);
      }
      final NameKind kind = switch (item.typeCode) {
        DataTypeCode.record => NameKind.record,
        DataTypeCode.cond => NameKind.condition,
        _ => NameKind.data,
      };
      if (kind == NameKind.record &&
          dictionary
              .named(name)
              .any((DictionaryEntry e) => e.kind == NameKind.record)) {
        // "A name associated with the RECORD type code must be unique"
        // (J 90.01.03); the id is ours (M3-17).
        diagnostics.reportAt(
          msgNameNotUnique,
          anchor,
          column: 7,
          operands: [name],
        );
      }
      _enter(name, kind, anchor, item: item);
    }
  }

  void _enterProcedureNames(List<Sentence> sentences) {
    // Statement labels scope to their section (D2.5); a BEGIN SECTION
    // sentence's label is the section's name.
    final sectionStack = <String>[];
    for (final sentence in sentences) {
      final bool opensSection = sentence.clauses.any(
        (Clause c) => c is BeginSectionClause,
      );
      final String? label = sentence.scan.label;
      if (label != null) {
        final SourceCard anchor = sentence.scan.cards.first;
        if (label != programStartName && keyWordClassOf(label) != null) {
          // An operation found in the name field (msg 61; M3-17).
          diagnostics.reportAt(
            msgOperationAsName,
            anchor,
            column: sentence.scan.labelColumn,
          );
        }
        final NameKind kind = opensSection
            ? NameKind.section
            : NameKind.statement;
        final String? scope = sectionStack.isEmpty ? null : sectionStack.last;
        final bool collides = dictionary
            .named(label)
            .any(
              (DictionaryEntry e) =>
                  (e.kind == NameKind.statement && e.section == scope) ||
                  e.kind == NameKind.section && kind == NameKind.section,
            );
        if (collides) {
          diagnostics.reportAt(
            msgNameNotUnique,
            anchor,
            column: sentence.scan.labelColumn,
            operands: [label],
          );
        }
        _enter(
          label,
          kind,
          anchor,
          sentence: sentence,
          section: kind == NameKind.statement ? scope : null,
        );
      }
      if (opensSection) {
        // The 18-level nesting limit is the parser's msg 915 (D9.7).
        sectionStack.add(label ?? '');
      }
      if (sentence.clauses.any((Clause c) => c is EndClause) &&
          sectionStack.isNotEmpty) {
        sectionStack.removeLast();
      }
    }
  }

  void _enter(
    String name,
    NameKind kind,
    SourceCard anchor, {
    DataItem? item,
    Sentence? sentence,
    String? section,
  }) {
    dictionary.add(
      name,
      kind,
      item: item,
      sentence: sentence,
      section: section,
    );
    if (tableLimits && dictionary.entries.length == 3501) {
      // D9.7's other message-less limit: the internal dictionary,
      // "Appox-Max" 3500 names (J 90.01.05).
      diagnostics.reportAt(msgDictionaryCapacity, anchor);
    }
  }

  void _checkListThreeShadows() {
    for (final DictionaryEntry entry in dictionary.entries) {
      if (entry.kind == NameKind.environment ||
          !_usedListThree.contains(entry.name)) {
        continue;
      }
      final SourceCard? anchor =
          entry.item?.entry.cards.first ?? entry.sentence?.scan.cards.first;
      if (anchor != null) {
        // List 3 bars a name only where the Environment Division uses
        // the word (J 02.03.03; M2-7; M3-17). The name stands.
        diagnostics.reportAt(
          msgListThreeWordAsName,
          anchor,
          operands: [entry.name],
        );
      }
    }
  }

  // ── The CALL pass (D4.13; M3-17) ─────────────────────────────────

  /// Enters every CALL synonym. Runs before the environment binder,
  /// which may resolve record names through synonyms.
  void callPass(List<List<Sentence>> procedureGroups) {
    walkClauses(procedureGroups, (Clause clause) {
      if (clause is! CallClause) {
        return;
      }
      for (final CallPair pair in clause.pairs) {
        if (pair.oldName.subscripts.isNotEmpty) {
          // "Subscripts may not be used in specifying the (old.name)"
          // (J 90.01.01); no id is attested (M3-21).
          report(msgCallOldNameSubscripted, pair.oldName.anchor);
          continue;
        }
        final DataItem? target = _resolveDataRef(pair.oldName);
        if (target == null) {
          continue;
        }
        if (pedantic && target.typeCode == DataTypeCode.record) {
          // "The use of record.names should be avoided in CALL
          // statements" (J 02.04.05) — advisory only (D4.13).
          report(msgCallOldNameIsRecord, pair.oldName.anchor);
        }
        final String name = pair.newName.text;
        if (name == programStartName) {
          diagnostics.reportAt(
            msgProgramStartMisdeclared,
            pair.newName.card,
            column: pair.newName.column,
          );
          continue;
        }
        if (dictionary.named(name).isNotEmpty) {
          // A synonym is "a new unique simple name" (D4.13).
          report(msgNameNotUnique, pair.newName, operands: [name]);
          continue;
        }
        _enter(name, NameKind.synonym, pair.newName.card, item: target);
      }
    });
  }

  // ── Reference resolution (M3-17) ─────────────────────────────────

  /// Resolves every data and condition reference of the procedure
  /// division. The I/O verb operands are the binder walk's (M3-18) and
  /// the transfer targets stage 3 of the walk's own rows (M3-20).
  void resolve(List<List<Sentence>> procedureGroups) {
    walkClauses(procedureGroups, _resolveClause);
    _checkConditionEntries();
    _checkStrayDescriptionNames();
  }

  void _resolveClause(Clause clause) {
    switch (clause) {
      case IfClause(:final condition):
        _resolveCond(condition);
      case MoveClause(:final source, :final targets):
        _resolveExpr(source);
        targets.forEach(_resolveDataRef);
      case SetClause(:final targets, :final value):
        targets.forEach(_resolveDataRef);
        _resolveExpr(value);
      case SetConditionClause(:final conditionName):
        _resolveConditionName(conditionName, setting: true);
      case AddClause(:final source, :final targets):
        _resolveExpr(source);
        targets.forEach(_resolveDataRef);
      case GoToClause(:final targets, :final index):
        for (final target in targets) {
          final CondExpr? when = target.when;
          if (when != null) {
            _resolveCond(when);
          }
        }
        if (index != null) {
          _resolveDataRef(index);
        }
      case DoClause(
        :final exactlyTimes,
        :final indices,
        :final usingArguments,
        :final givingResults,
      ):
        if (exactlyTimes != null) {
          _resolveExpr(exactlyTimes);
        }
        for (final index in indices) {
          _resolveDataRef(index.index);
          _resolveExpr(index.from);
          _resolveExpr(index.by);
          _resolveExpr(index.to);
        }
        usingArguments.forEach(_resolveExpr);
        givingResults.forEach(_resolveDataRef);
      case DisplayClause(:final items):
        items.forEach(_resolveExpr);
      case BeginSectionClause(:final usingParameters, :final givingFunctions):
        usingParameters.forEach(_resolveDataRef);
        givingFunctions.forEach(_resolveDataRef);
      case CallClause() || // The CALL pass ran already.
          OpenClause() || // The I/O operands are the binder walk's
          CloseClause() || // (M3-18).
          GetClause() ||
          FileClause() ||
          StopClause() ||
          EnterClause() ||
          NoteClause() ||
          EndClause() ||
          DeferredVerbClause():
        break;
    }
  }

  void _resolveExpr(ArithExpr expr) {
    switch (expr) {
      case NameOperand(:final name):
        _resolveDataRef(name);
      case BinaryExpr(:final left, :final right):
        _resolveExpr(left);
        _resolveExpr(right);
      case UnaryExpr(:final operand):
        _resolveExpr(operand);
      case TruthExpr(:final condition):
        _resolveCond(condition);
      case FunctionCall(:final function, :final arguments):
        _resolveDataRef(function);
        arguments.forEach(_resolveDataRef);
      case LiteralOperand() || FigurativeOperand():
        break;
    }
  }

  void _resolveCond(CondExpr condition) {
    switch (condition) {
      case Relation(:final left, :final right):
        _resolveExpr(left);
        _resolveExpr(right);
      case ConditionReference(:final name):
        _resolveConditionName(name, setting: false);
      case AndExpr(:final left, :final right):
        _resolveCond(left);
        _resolveCond(right);
      case OrExpr(:final left, :final right):
        _resolveCond(left);
        _resolveCond(right);
      case NotExpr(:final operand):
        _resolveCond(operand);
    }
  }

  /// The M3-17 triage over a data-reference site. Returns the resolved
  /// item, or `null` after a diagnostic.
  DataItem? _resolveDataRef(NameReference ref) {
    final bool enclosing = _inSubscript;
    _inSubscript = true;
    ref.subscripts.forEach(_resolveExpr);
    _inSubscript = enclosing;
    final String last = ref.words.last.text;
    final DictionaryEntry? synonym = dictionary.synonym(last);
    if (synonym != null) {
      if (ref.words.length > 1) {
        // A synonym is never qualified (D4.13; Open Question 56).
        report(msgImproperlyQualified, ref.anchor, operands: [ref.text]);
        return null;
      }
      return _resolvedTo(ref, synonym.item!);
    }
    final List<DataItem> declared = mapper.itemsNamed(last);
    final List<DataItem> candidates = [
      for (final DataItem item in declared)
        if ((_inSubscript || item.typeCode != DataTypeCode.cond) &&
            _chainMatches(item, ref))
          item,
    ];
    if (candidates.length == 1) {
      return _resolvedTo(ref, candidates.single);
    }
    if (candidates.length > 1) {
      report(msgNameNotUnique, ref.anchor, operands: [ref.text]);
      return null;
    }
    if (declared.isNotEmpty) {
      // Declared somewhere, but no candidate matches the qualifiers —
      // condition names among them: they resolve only where a
      // condition may stand (D5.6).
      final Message message =
          declared.every((DataItem item) => item.typeCode == DataTypeCode.cond)
          ? msgImproperFormatForUse
          : msgImproperlyQualified;
      report(message, ref.anchor, operands: [ref.text]);
      return null;
    }
    if (dictionary.named(last).isNotEmpty) {
      // The name exists only as an environment or procedure name — a
      // format-less object at a data site (M3-17 as amended).
      report(msgImproperFormatForUse, ref.anchor, operands: [ref.text]);
      return null;
    }
    report(msgUndefinedSymbol, ref.anchor, operands: [ref.text]);
    return null;
  }

  DataItem _resolvedTo(NameReference ref, DataItem item) {
    dataResolutions[ref] = item;
    _subscripts.check(ref, item);
    return item;
  }

  /// Whether [item]'s ancestor-name chain contains [ref]'s qualifier
  /// words in order, general to specific (J 02.05.02–03: level and
  /// position only, REDEF-blind; F p. 16: intermediate levels may be
  /// skipped).
  bool _chainMatches(DataItem item, NameReference ref) {
    int wordIndex = ref.words.length - 2;
    for (
      DataItem? ancestor = item.parent;
      ancestor != null && wordIndex >= 0;
      ancestor = ancestor.parent
    ) {
      if (!ancestor.nameDiscarded &&
          ancestor.entry.name == ref.words[wordIndex].text) {
        wordIndex--;
      }
    }
    return wordIndex < 0;
  }

  void _resolveConditionName(NameReference ref, {required bool setting}) {
    final String last = ref.words.last.text;
    if (ref.words.length == 1 && _keysConditionNames.contains(last)) {
      if (setting) {
        // Console keys cannot be stored into; the reading is ours
        // (M3-17).
        report(msgNotProperlyDefined, ref.anchor, operands: [last]);
      } else {
        keysConditions.add(ref);
      }
      return;
    }
    final List<DataItem> declared = mapper.itemsNamed(last);
    final List<DataItem> candidates = [
      for (final DataItem item in declared)
        if (_chainMatches(item, ref)) item,
    ];
    if (candidates.length > 1) {
      report(msgNameNotUnique, ref.anchor, operands: [ref.text]);
      return;
    }
    if (candidates.isEmpty) {
      if (declared.isNotEmpty) {
        report(msgImproperlyQualified, ref.anchor, operands: [ref.text]);
      } else if (dictionary.named(last).isNotEmpty) {
        report(
          setting ? msgNotProperlyDefined : msgImproperFormatForUse,
          ref.anchor,
          operands: [ref.text],
        );
      } else {
        report(msgUndefinedSymbol, ref.anchor, operands: [ref.text]);
      }
      return;
    }
    final DataItem item = candidates.single;
    if (item.typeCode != DataTypeCode.cond) {
      // A non-condition where only a condition may stand (D5.6;
      // M3-17): the test is dropped, or the SET is not a switch
      // setting.
      report(
        setting ? msgNotProperlyDefined : msgImproperFormatForUse,
        ref.anchor,
        operands: [ref.text],
      );
      return;
    }
    dataResolutions[ref] = item;
  }

  // ── Data-division checks (msgs 37, 185; M3-17) ───────────────────

  void _checkConditionEntries() {
    for (final DataItem item in mapper.items) {
      if (item.typeCode != DataTypeCode.cond) {
        continue;
      }
      final DataItem? variable = item.parent;
      final ItemSemantics? sem = variable == null
          ? null
          : mapper.semantics[variable];
      final Pictorial? shape = sem?.shape;
      if (sem == null || shape == null) {
        // A COND entry "must be preceded by a higher level entry
        // defining the format" (J 02.05.02).
        _reportCond(item, variable?.entry.name ?? item.entry.name);
        continue;
      }
      final Token? constant = item.constant;
      if (constant == null) {
        continue; // The absence drew msg 4-family rows at M2.
      }
      final int length = constantBcd(constant, item.entry.cards).length;
      final bool mismatch = switch (sem.fieldClass) {
        // External decimal: "the length specified by the pictorial
        // must be exactly equal to the length of the constant"
        // (J 02.05.07).
        FieldClass.externalDecimal => length != shape.storageChars,
        // Internal decimal: right-justified into the capacity; larger
        // is the fault (J 02.05.07).
        FieldClass.internalDecimal => length > shape.valueDigits,
        // Alphameric: longer than the pictorial is the fault
        // (J 02.05.06).
        FieldClass.alphameric => length > sem.storageChars,
        // A value cannot match an edited image (J 02.05.06 i).
        FieldClass.edited => true,
        _ => false,
      };
      if (mismatch) {
        _reportCond(item, variable!.entry.name);
      }
    }
  }

  void _reportCond(DataItem item, String variableName) {
    diagnostics.reportAt(
      msgConditionalVariableFormat,
      item.entry.cards.first,
      column: 7,
      operands: [variableName],
    );
  }

  void _checkStrayDescriptionNames() {
    for (final DataItem item in mapper.items) {
      if (item.typeCode == DataTypeCode.redef ||
          item.typeCode == DataTypeCode.copy) {
        continue;
      }
      var faulted = false;
      final Token? stray = item.targetName;
      // A measured shape with no pictorial token means the mapper read
      // the stray run as the format — the unclosed-count repair
      // (msg 133) among them.
      final bool strayIsFormat =
          item.pictorial == null && mapper.semantics[item]?.shape != null;
      if (stray != null && !strayIsFormat) {
        // A description run with a non-format character reads as a
        // name; it must be "a data, key, or a procedure name"
        // (J 02.05.06 e).
        final String name = stray.text;
        final bool known =
            keyWordClassOf(name) != null ||
            mapper.itemsNamed(name).isNotEmpty ||
            dictionary.named(name).isNotEmpty;
        if (!known) {
          diagnostics.report(msgPictorialError, stray);
          faulted = true;
        }
      }
      if (!faulted &&
          item.extras.isNotEmpty &&
          !(mapper.semantics[item]?.shape?.missingRightParen ?? false)) {
        // Description tokens no clause claimed (M2-3); one message per
        // entry (M3-17). An unclosed repetition count is exempt: its
        // trailing digits were read as the count and drew msg 133.
        diagnostics.report(msgPictorialError, item.extras.first);
      }
    }
  }
}

/// The procedure walk the stage-2 phases share (M3-17): every clause of
/// every live sentence, IF arms and ON OVERFLOW clauses included, with
/// the clause number the `n,cc` diagnostic form needs (M2-6).
abstract base class ClauseWalk {
  ClauseWalk(this.diagnostics);

  final List<Diagnostic> diagnostics;

  int _clause = 0;

  void walkClauses(
    List<List<Sentence>> procedureGroups,
    void Function(Clause) visit,
  ) {
    void walk(Clause clause) {
      _clause = clause.clause;
      visit(clause);
      switch (clause) {
        case IfClause(:final thenArm, :final otherwiseArm):
          thenArm.forEach(walk);
          otherwiseArm.forEach(walk);
        case SetClause(:final onOverflow) when onOverflow != null:
          walk(onOverflow);
        case AddClause(:final onOverflow) when onOverflow != null:
          walk(onOverflow);
        case GetClause(:final atEnd) when atEnd?.statement != null:
          walk(atEnd!.statement!);
        default:
          break;
      }
      _clause = 0;
    }

    for (final sentences in procedureGroups) {
      for (final sentence in sentences) {
        if (sentence.deleted) {
          continue;
        }
        sentence.clauses.forEach(walk);
      }
    }
  }

  /// Reports [message] at [at], carrying the current clause number
  /// when the site is inside one (M2-6).
  void report(Message message, Token at, {List<String> operands = const []}) {
    final diagnostic = Diagnostic(
      message,
      at.card,
      column: at.column,
      operands: operands,
    );
    if (_clause > 0) {
      diagnostic.clause = _clause;
    }
    diagnostics.add(diagnostic);
  }
}
