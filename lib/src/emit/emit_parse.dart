/// The `--emit-parse` dump: every job's parse tree, as a labeled
/// reconstruction (`docs/design/emit-stages.md`).
///
/// The line form is one node, one line, with two spaces of indent per
/// depth and the node kind in lower case. Two rules place a field: a
/// scalar field — a flag, a number, one token — prints inline on its
/// owner's line; a node field and a list field print one child line
/// each, prefixed by the field's role where the position alone would
/// not tell. A unit root — sentence, data item, environment card —
/// carries the front end's `n,cc` statement number (J 02.02.01; D7.13),
/// the number the listing prints against the same unit. Card numbers
/// and columns stay out: they are the scan dump's material.
library;

import '../ast/control_ast.dart';
import '../ast/data_ast.dart';
import '../ast/environment_ast.dart';
import '../ast/procedure_ast.dart';
import '../driver/driver.dart';
import '../lexer/data_lexer.dart';
import '../lexer/source_card.dart';
import '../lexer/token.dart';
import '../parser/parser.dart';
import 'common.dart';

/// Renders the parse of every job of [deck], deck order.
String emitParse(DeckCompilation deck) {
  final out = StringBuffer()..writeln(reconstructionLabel);
  for (var i = 0; i < deck.jobs.length; i++) {
    if (i > 0) {
      out.writeln();
    }
    out.writeln(jobHeader(i + 1));
    final ParseResult? parse = deck.jobs[i].parse;
    if (parse == null) {
      out.writeln(stageNotReached);
      continue;
    }
    _ParseDump(out, parse.frontEnd.statementNumberByCard).result(parse);
  }
  return out.toString();
}

final class _ParseDump {
  _ParseDump(this._out, this._numbers);

  final StringBuffer _out;

  /// The front end's `n,00` number of every card inside a statement
  /// unit, keyed by card number.
  final Map<int, String> _numbers;

  void result(ParseResult parse) {
    final CompileCard? compileCard = parse.compileCard;
    if (compileCard != null) {
      _compileCard(compileCard);
    }
    parse.groups.forEach(_group);
    if (parse.stopped) {
      // Every group after this point went unparsed (D9.1; D10.2).
      _line(0, const ['parse-stopped']);
    }
  }

  void _compileCard(CompileCard card) {
    final String identifier = card.secondaryIdentifier.trimRight();
    _line(0, [
      'compile-card',
      if (card.historicalSpelling) '*COMPILE' else r'$CMPLE',
      if (card.deckName.isNotEmpty) 'deck ${card.deckName}',
      if (identifier.isNotEmpty) "identifier '$identifier'",
    ]);
    for (final String option in card.options) {
      _line(1, ['option $option']);
    }
  }

  void _group(ParsedGroup group) {
    switch (group) {
      case ParsedDataGroup(:final roots):
        _line(0, const ['data-group']);
        for (final item in roots) {
          _dataItem(item, 1);
        }
      case ParsedEnvironmentGroup(:final cards):
        _line(0, const ['environment-group']);
        for (final card in cards) {
          _environmentCard(card, 1);
        }
      case ParsedProcedureGroup(:final sentences):
        _line(0, const ['procedure-group']);
        for (final sentence in sentences) {
          _sentence(sentence, 1);
        }
    }
  }

  // --- Data ----------------------------------------------------------

  void _dataItem(DataItem item, int depth) {
    final DataEntry entry = item.entry;
    final int? level = entry.level;
    final Token? pictorial = item.pictorial;
    final Token? constant = item.constant;
    final Token? targetName = item.targetName;
    final Token? quantityIn = item.quantityInName;
    _line(depth, [
      _number(entry.cards.first),
      'data-item',
      if (entry.name.isNotEmpty) entry.name,
      if (level != null) 'level ${level.toString().padLeft(2, '0')}',
      if (level == null && entry.levelText.trim().isNotEmpty)
        'level ${entry.levelText.trim()}',
      ..._typeAtoms(item),
      if (entry.quantity != null) 'quantity ${entry.quantity}',
      if (entry.quantity == null && entry.quantityText.isNotEmpty)
        'quantity ${entry.quantityText}',
      if (entry.modeText.isNotEmpty) 'mode ${entry.modeText}',
      if (entry.justifyText.isNotEmpty) 'justify ${entry.justifyText}',
      if (pictorial != null) 'pictorial ${pictorial.text}',
      if (constant != null) 'constant ${_literal(constant)}',
      if (targetName != null) 'target ${targetName.text}',
      if (quantityIn != null) 'quantity-in ${quantityIn.text}',
      if (item.blankWhenZero) 'blank-when-zero',
      if (item.nameDiscarded) 'name-discarded',
    ]);
    for (final Token extra in item.extras) {
      _line(depth + 1, ['extra ${extra.text}']);
    }
    for (final DataItem child in item.children) {
      _dataItem(child, depth + 1);
    }
  }

  /// The type-code atom: the recognized code, or the raw field marked
  /// `unrecognized` — a withdrawn or invented code the parser refused
  /// (J 02.05.03).
  List<String> _typeAtoms(DataItem item) {
    final DataTypeCode? code = item.typeCode;
    if (code == null) {
      final String text = item.entry.typeText;
      return text.isEmpty ? const [] : ['type $text unrecognized'];
    }
    return switch (code) {
      DataTypeCode.none => const [],
      DataTypeCode.record => const ['type RECORD'],
      DataTypeCode.cond => const ['type COND'],
      DataTypeCode.redef => const ['type REDEF'],
      DataTypeCode.copy => const ['type COPY'],
      DataTypeCode.label => const ['type LABEL'],
      DataTypeCode.rcdmrk => const ['type RCDMRK'],
    };
  }

  // --- Environment ---------------------------------------------------

  void _environmentCard(EnvironmentCard card, int depth) {
    final String number = _number(card.spec.cards.first);
    final String name = card.spec.name;
    switch (card) {
      case FileCard():
        final Token? onError = card.onError;
        final Token? forLabel = card.forLabel;
        _line(depth, [
          number,
          'file-card',
          name,
          _direction(card.direction),
          if (card.binary) 'binary',
          if (card.card) 'card',
          if (card.blocksize != null) 'blocksize ${card.blocksize}',
          if (onError != null) 'on-error ${onError.text}',
          if (forLabel != null) 'for-label ${forLabel.text}',
          if (card.holdOrSpans) 'hold-or-spans',
          if (card.begin) 'begin',
        ]);
        for (final FileRecordClause record in card.records) {
          _fileRecord(record, depth + 1);
        }
      case SpecifCard():
        final Token? fileName = card.fileName;
        _line(depth, [
          number,
          'specif-card',
          name,
          if (fileName != null) fileName.text,
          if (card.unit1 != null) 'unit1 ${card.unit1}',
          if (card.unit2 != null) 'unit2 ${card.unit2}',
          if (card.density != null) 'density ${card.density}',
          if (card.defer) 'defer',
          if (card.openW) 'openw',
          if (card.openF) 'openf',
          if (card.closeMode != null) 'close ${card.closeMode}',
          if (card.activity != null) 'activity ${card.activity}',
          if (card.checkpoint != null) 'checkpoint ${card.checkpoint}',
          if (card.multi) 'multi',
          if (card.seq) 'seq',
          if (card.cksums) 'cksums',
          if (card.labels != null) 'labels ${card.labels}',
          if (card.labelDensity != null) 'label-density ${card.labelDensity}',
          if (card.serial != null) 'serial ${card.serial}',
          if (card.reel != null) 'reel ${card.reel}',
          if (card.retain != null) 'retain ${card.retain}',
        ]);
      case PoolCard():
        _line(depth, [
          number,
          'pool-card',
          name,
          if (card.bufferCount != null) 'buffercount ${card.bufferCount}',
          if (card.blocksize != null) 'blocksize ${card.blocksize}',
        ]);
        for (final Token file in card.fileNames) {
          _line(depth + 1, ['file ${file.text}']);
        }
      case GroupCard():
        _line(depth, [
          number,
          'group-card',
          name,
          if (card.openCount != null) 'opencount ${card.openCount}',
          if (card.bufferCount != null) 'buffercount ${card.bufferCount}',
        ]);
        for (final Token member in card.names) {
          _line(depth + 1, ['name ${member.text}']);
        }
      case ContrlCard():
        final Token? to = card.to;
        _line(depth, [
          number,
          'contrl-card',
          name,
          card.first.text,
          if (to != null) 'to ${to.text}',
        ]);
      case OptionCard():
        final Token? collateIn = card.collateIn;
        final Token? conserveIn = card.conserveIn;
        _line(depth, [
          number,
          'option-card',
          name,
          if (card.collateCom) 'collate COM',
          if (collateIn != null) 'collate-in ${collateIn.text}',
          if (card.conserve != null) 'conserve ${card.conserve}',
          if (conserveIn != null) 'conserve-in ${conserveIn.text}',
        ]);
      case CondCard():
        _line(depth, [number, 'cond-card', name, 'setting ${card.setting}']);
    }
  }

  void _fileRecord(FileRecordClause record, int depth) {
    final Token? findLengthIn = record.findLengthIn;
    final Token? placeLengthIn = record.placeLengthIn;
    _line(depth, [
      'record',
      record.name.text,
      if (record.blockControl) 'block-control',
      if (findLengthIn != null) 'find-length-in ${findLengthIn.text}',
      if (placeLengthIn != null) 'place-length-in ${placeLengthIn.text}',
      if (record.primary) 'primary',
      if (record.noControlWord) 'no-control-word',
    ]);
  }

  // --- Procedure -----------------------------------------------------

  void _sentence(Sentence sentence, int depth) {
    final String? label = sentence.scan.label;
    _line(depth, [
      _number(sentence.scan.cards.first),
      'sentence',
      if (label != null) 'label $label',
      if (sentence.deleted) 'deleted',
    ]);
    for (final Clause clause in sentence.clauses) {
      _clause(clause, depth + 1);
    }
  }

  void _clause(Clause clause, int depth, {String role = ''}) {
    switch (clause) {
      case IfClause(:final condition, :final thenArm, :final otherwiseArm):
        _line(depth, [role, 'if-clause']);
        _cond(condition, depth + 1);
        for (final arm in thenArm) {
          _clause(arm, depth + 1, role: 'then');
        }
        for (final arm in otherwiseArm) {
          _clause(arm, depth + 1, role: 'otherwise');
        }
      case MoveClause(:final corresponding, :final source, :final targets):
        _line(depth, [role, 'move-clause', if (corresponding) 'corresponding']);
        _arith(source, depth + 1, role: 'source');
        for (final target in targets) {
          _name(target, depth + 1, role: 'target');
        }
      case SetClause(
        :final targets,
        :final value,
        :final truncated,
        :final onOverflow,
      ):
        _line(depth, [role, 'set-clause', if (truncated) 'truncated']);
        for (final target in targets) {
          _name(target, depth + 1, role: 'target');
        }
        _arith(value, depth + 1, role: 'value');
        if (onOverflow != null) {
          _clause(onOverflow, depth + 1, role: 'on-overflow');
        }
      case SetConditionClause(:final conditionName):
        _line(depth, [role, 'set-condition-clause']);
        _name(conditionName, depth + 1, kind: 'condition-name');
      case AddClause(
        :final corresponding,
        :final source,
        :final targets,
        :final truncated,
        :final onOverflow,
      ):
        _line(depth, [
          role,
          'add-clause',
          if (corresponding) 'corresponding',
          if (truncated) 'truncated',
        ]);
        _arith(source, depth + 1, role: 'source');
        for (final target in targets) {
          _name(target, depth + 1, role: 'target');
        }
        if (onOverflow != null) {
          _clause(onOverflow, depth + 1, role: 'on-overflow');
        }
      case GoToClause(:final targets, :final index):
        _line(depth, [role, 'go-to-clause']);
        for (final target in targets) {
          _name(target.name, depth + 1, role: 'target');
          final CondExpr? when = target.when;
          if (when != null) {
            _cond(when, depth + 2, role: 'when');
          }
        }
        if (index != null) {
          _name(index, depth + 1, role: 'index');
        }
      case DoClause(
        :final procedure,
        :final exactlyTimes,
        :final indices,
        :final usingArguments,
        :final givingResults,
      ):
        _line(depth, [role, 'do-clause']);
        _name(procedure, depth + 1, role: 'procedure');
        if (exactlyTimes != null) {
          _arith(exactlyTimes, depth + 1, role: 'exactly');
        }
        for (final specification in indices) {
          _name(specification.index, depth + 1, role: 'for');
          _arith(specification.from, depth + 2, role: 'from');
          _arith(specification.by, depth + 2, role: 'by');
          _arith(specification.to, depth + 2, role: 'to');
        }
        for (final argument in usingArguments) {
          _arith(argument, depth + 1, role: 'using');
        }
        for (final result in givingResults) {
          _name(result, depth + 1, role: 'giving');
        }
      case StopClause(:final run, :final number):
        _line(depth, [
          role,
          'stop-clause',
          if (run) 'RUN',
          if (number != null) number.text,
        ]);
      case OpenClause(:final allFiles, :final files):
        _line(depth, [role, 'open-clause', if (allFiles) 'all-files']);
        for (final file in files) {
          _name(file, depth + 1, role: 'file');
        }
      case CloseClause(:final allFiles, :final files):
        _line(depth, [role, 'close-clause', if (allFiles) 'all-files']);
        for (final file in files) {
          _name(file, depth + 1, role: 'file');
        }
      case GetClause(:final recordFrom, :final name, :final atEnd):
        _line(depth, [role, 'get-clause', if (recordFrom) 'record-from']);
        _name(name, depth + 1, role: recordFrom ? 'file' : 'record');
        if (atEnd != null) {
          _atEnd(atEnd, depth + 1);
        }
      case FileClause(:final record, :final inFile):
        _line(depth, [role, 'file-clause']);
        _name(record, depth + 1, role: 'record');
        if (inFile != null) {
          _name(inFile, depth + 1, role: 'in');
        }
      case DisplayClause(:final items):
        _line(depth, [role, 'display-clause']);
        for (final item in items) {
          _arith(item, depth + 1);
        }
      case CallClause(:final pairs):
        _line(depth, [role, 'call-clause']);
        for (final pair in pairs) {
          _line(depth + 1, ['call-pair', 'new ${pair.newName.text}']);
          _name(pair.oldName, depth + 2, role: 'old');
        }
      case EnterClause(:final crypt):
        _line(depth, [
          role,
          'enter-clause',
          if (crypt) 'CRYPT' else 'COMMERCIAL TRANSLATOR',
        ]);
      case NoteClause(:final text):
        _line(depth, [role, 'note-clause']);
        for (final fragment in text) {
          // One fragment per card, kept apart: the free text is not
          // tokenized, so a joined line would hide the card break.
          _line(depth + 1, ['text ${fragment.text}']);
        }
      case BeginSectionClause(:final usingParameters, :final givingFunctions):
        _line(depth, [role, 'begin-section-clause']);
        for (final parameter in usingParameters) {
          _name(parameter, depth + 1, role: 'using');
        }
        for (final function in givingFunctions) {
          _name(function, depth + 1, role: 'giving');
        }
      case EndClause(:final sectionName):
        _line(depth, [role, 'end-clause']);
        if (sectionName != null) {
          _name(sectionName, depth + 1);
        }
      case DeferredVerbClause(:final verb, :final operands):
        _line(depth, [role, 'deferred-verb-clause', verb.text]);
        for (final operand in operands) {
          _line(depth + 1, ['operand ${operand.text}']);
        }
    }
  }

  void _atEnd(AtEndClause atEnd, int depth) {
    _line(depth, const ['at-end-clause']);
    final Clause? statement = atEnd.statement;
    if (statement != null) {
      _clause(statement, depth + 1);
    }
    final NameReference? bareName = atEnd.bareName;
    if (bareName != null) {
      // The bare-name form compiles as `DO name` (D6.6).
      _name(bareName, depth + 1);
    }
  }

  // --- Expressions ---------------------------------------------------

  void _arith(ArithExpr expr, int depth, {String role = ''}) {
    switch (expr) {
      case NameOperand(:final name):
        _name(name, depth, role: role);
      case LiteralOperand(:final literal):
        _line(depth, [role, 'literal', _literal(literal)]);
      case FigurativeOperand(:final word):
        _line(depth, [role, 'figurative', word.text]);
      case BinaryExpr(
        :final left,
        :final operator,
        :final right,
        :final recovered,
      ):
        // A recovered grouping generates no code (D4.10).
        _line(depth, [
          role,
          'binary',
          operator.text,
          if (recovered) 'recovered',
        ]);
        _arith(left, depth + 1);
        _arith(right, depth + 1);
      case UnaryExpr(:final operator, :final operand):
        _line(depth, [role, 'unary', operator.text]);
        _arith(operand, depth + 1);
      case TruthExpr(:final condition):
        _line(depth, [role, 'truth']);
        _cond(condition, depth + 1);
      case FunctionCall(:final function, :final arguments):
        _line(depth, [role, 'function-call']);
        _name(function, depth + 1, role: 'function');
        for (final argument in arguments) {
          _name(argument, depth + 1, role: 'argument');
        }
    }
  }

  void _cond(CondExpr expr, int depth, {String role = ''}) {
    switch (expr) {
      case Relation(:final left, :final op, :final negated, :final right):
        _line(depth, [role, 'comparison', if (negated) 'NOT', _relation(op)]);
        _arith(left, depth + 1);
        _arith(right, depth + 1);
      case ConditionReference(:final name):
        _name(name, depth, role: role, kind: 'condition-name');
      case AndExpr(:final left, :final right):
        _line(depth, [role, 'and']);
        _cond(left, depth + 1);
        _cond(right, depth + 1);
      case OrExpr(:final left, :final right):
        _line(depth, [role, 'or']);
        _cond(left, depth + 1);
        _cond(right, depth + 1);
      case NotExpr(:final operand):
        _line(depth, [role, 'not']);
        _cond(operand, depth + 1);
    }
  }

  void _name(
    NameReference name,
    int depth, {
    String role = '',
    String kind = 'name',
  }) {
    _line(depth, [role, kind, name.text]);
    for (final ArithExpr subscript in name.subscripts) {
      _arith(subscript, depth + 1, role: 'subscript');
    }
  }

  /// The unit's statement number, or `9999,99` when the front end
  /// numbered no card of it — a stopped scan (J 02.02.01; D9.5).
  String _number(SourceCard card) => _numbers[card.cardNumber] ?? '9999,99';

  void _line(int depth, List<String> atoms) {
    final String text = atoms.where((String a) => a.isNotEmpty).join(' ');
    _out.writeln('${'  ' * depth}$text');
  }
}

String _relation(RelationOp op) => switch (op) {
  RelationOp.greater => 'GREATER',
  RelationOp.less => 'LESS',
  RelationOp.equal => 'EQUAL',
};

String _direction(FileDirection direction) => switch (direction) {
  FileDirection.input => 'INPUT',
  FileDirection.output => 'OUTPUT',
  FileDirection.checkpoint => 'CHECKPOINT',
};

/// An alphameric literal prints inside its quotation marks, which the
/// scanner strips ([Token.text]); every other token prints as written.
String _literal(Token token) => switch (token.kind) {
  TokenKind.alphamericLiteral => "'${token.text}'",
  TokenKind.word ||
  TokenKind.numericLiteral ||
  TokenKind.floatingLiteral ||
  TokenKind.symbol ||
  TokenKind.noteText ||
  TokenKind.descriptionItem => token.text,
};
