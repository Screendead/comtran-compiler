/// The severity table (decision D9.2).
///
/// Per-message severity values are historically unrecoverable — the 90.04
/// catalog prints code 0 throughout because "the value may vary"
/// (J 90.04.01) — so every value here is OUR assignment, non-historical,
/// derived by the D9.2 consequence rule: the consequence stated in the
/// message's own text wins over its class heading. Classes: C1 advisory
/// or auto-repair = 1; C2 operand-level loss = 2; C3 statement-level
/// loss = 3; C4 program-level loss = 4; C5 unrecoverable, internal, or
/// capacity = 5. The compiler reads severities from this table only
/// (D9.2); the full 210-row table is produced at M2 — these are the rows
/// M1 needs.
library;

/// Severity value per message id. Every row is a non-historical D9.2
/// assignment; the class justification is on the row.
const Map<String, int> messageSeverities = {
  // C3: the FILE card cannot bind without a name; the specification is
  // lost at statement level.
  '1,00': 3,
  // C2: the oversized literal operand is lost.
  '52,00': 2,
  // C2: the malformed literal operand is lost.
  '53,00': 2,
  // C1: the compiler repairs (period assumed) and carries on.
  '62,00': 1,
  // C3: the COND card cannot bind without a name.
  '88,00': 3,
  // C2: the oversized pictorial operand is lost.
  '100,00': 2,
  // C1: the text states the repair (0 internal, $ external); D9.10
  // assigns class C1 explicitly.
  '134,00': 1,
  // C3: the card is deleted (J 02.06.01.01) — statement-level loss.
  '144,00': 3,
  // C5: the text states an internal table capacity condition.
  '148,00': 5,
  // C2: the oversized literal operand is lost.
  '150,00': 2,
  // C2: the unclosed literal operand is lost.
  '167,00': 2,
  // C2: the unclosed literal operand is lost.
  '168,00': 2,
  // C1: advisory — "SHOULD BE PUNCHED", "POSSIBLE … ERROR"; the entry
  // still assembles from its first card.
  '186,00': 1,
  // C1: the text states the repair (external mode substituted).
  '189,00': 1,
  // C1: the text states the repair (field not justified).
  '190,00': 1,
  // C3: the entry cannot take its place in the hierarchy without a
  // level; statement-level loss.
  '194,00': 3,
  // C1 (ours): the stray period is ignored and scanning continues.
  '900,00': 1,
  // C2 (ours): the over-long name operand cannot resolve.
  '901,00': 2,
  // C3 (ours, D2.3): the card is ignored — statement-level loss.
  '902,00': 3,
  // C3 (ours, D9.14): the card is ignored — statement-level loss.
  '903,00': 3,
  // C1 (ours): the duplicate card is ignored and compilation carries on.
  '904,00': 1,
};
