/// The code generator's messages (M4-18): one catalog entry the pool
/// counter draws, and two of ours behind `--pedantic`.
library;

import '../lexer/message_catalog.dart';
import '../lexer/messages.dart';

/// `172,00` — the constant pool past its printed 500 entries
/// ([J 90.01.05] item k; D9.7).
final Message msgConstantPoolOverflow = messageCatalog['172,00']!;

/// Ours — `--pedantic` only: constant DO FOR parameters whose index
/// never steps from p to r exactly under the decoded magnitude exit — a
/// zero or negative q, p above r, or a q that does not divide r − p
/// (D5.1; M4-13).
const Message msgLoopParametersDoNotStep = Message.ours(
  '946,00',
  "-DO- ... -FOR- 'NAME.1' PARAMETERS DO NOT STEP FROM THE INITIAL TO "
      'THE TERMINAL VALUE. ACCEPTED. (NON-HISTORICAL.)',
);

/// Ours — `--pedantic` only: a DO whose procedure can DO its way back
/// into a procedure already active, which overwrites the pending
/// return in the one-word cell (D5.7; M4-13).
const Message msgDoReentersActiveProcedure = Message.ours(
  '947,00',
  "-DO- OF 'NAME.1' CAN RE-ENTER AN ACTIVE PROCEDURE. THE PENDING "
      'RETURN IS LOST. (NON-HISTORICAL.)',
);
