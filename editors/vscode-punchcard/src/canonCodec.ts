/**
 * The canon container format (`.ctd`).
 *
 * A direct port of `lib/src/cards/canon_codec.dart` and `card_image.dart`,
 * which implement §2 of `docs/design/deck-format.md` (decision D0.5): a 12-byte
 * header (magic `CTDECK`, version, flags, big-endian card count) followed by one
 * 120-byte record per card, columns packed two-per-three-bytes.
 */

/** Columns per card. */
export const COLUMN_COUNT = 80;

/** The current canon format version. */
export const CANON_FORMAT_VERSION = 1;

/** Header size in bytes. */
export const HEADER_LENGTH = 12;

/** Card record size in bytes. */
export const RECORD_LENGTH = 120;

const MAGIC = [0x43, 0x54, 0x44, 0x45, 0x43, 0x4b]; // 'CTDECK'

/**
 * One punched card at punch level: 80 columns of 12 bits. Bit 11 is row 12
 * (top), bit 10 row 11, bit 9 row 0, bits 8-0 rows 1-9.
 */
export type Card = Uint16Array;

/** A card with no punches. */
export function blankCard(): Card {
  return new Uint16Array(COLUMN_COUNT);
}

/** A copy of `card`. */
export function copyCard(card: Card): Card {
  return Uint16Array.from(card);
}

/** Whether no column of `card` is punched. */
export function isBlankCard(card: Card): boolean {
  return card.every((c) => c === 0);
}

/** Throws when `card` is not 80 columns of 12-bit values. */
export function checkCard(card: Card): void {
  if (card.length !== COLUMN_COUNT) {
    throw new Error(`a card has exactly ${COLUMN_COUNT} columns`);
  }
  for (const c of card) {
    if (c > 0xfff) {
      throw new Error(`column value ${c} does not fit 12 bits`);
    }
  }
}

/** Encodes `deck` as canon bytes. */
export function encodeCanon(deck: readonly Card[]): Uint8Array {
  const bytes = new Uint8Array(HEADER_LENGTH + RECORD_LENGTH * deck.length);
  bytes.set(MAGIC, 0);
  bytes[6] = CANON_FORMAT_VERSION;
  bytes[7] = 0; // Flags, reserved.
  new DataView(bytes.buffer).setUint32(8, deck.length, false);
  let offset = HEADER_LENGTH;
  for (const card of deck) {
    checkCard(card);
    for (let i = 0; i < COLUMN_COUNT; i += 2) {
      const a = card[i];
      const b = card[i + 1];
      bytes[offset] = a >> 4;
      bytes[offset + 1] = ((a & 0xf) << 4) | (b >> 8);
      bytes[offset + 2] = b & 0xff;
      offset += 3;
    }
  }
  return bytes;
}

/**
 * Decodes canon bytes into a deck.
 *
 * Throws on a bad magic, an unknown version, nonzero flags, or a length that is
 * not exactly a header plus whole card records matching the header's count
 * (spec §2.1).
 */
export function decodeCanon(bytes: Uint8Array): Card[] {
  if (bytes.length < HEADER_LENGTH) {
    throw new Error('canon file shorter than the 12-byte header');
  }
  for (let i = 0; i < MAGIC.length; i++) {
    if (bytes[i] !== MAGIC[i]) {
      throw new Error('bad magic: not a CTDECK file');
    }
  }
  if (bytes[6] !== CANON_FORMAT_VERSION) {
    throw new Error(`unknown canon format version ${bytes[6]}`);
  }
  if (bytes[7] !== 0) {
    throw new Error(`reserved flags byte is nonzero (${bytes[7]})`);
  }
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const count = view.getUint32(8, false);
  const expected = HEADER_LENGTH + RECORD_LENGTH * count;
  if (bytes.length !== expected) {
    throw new Error(
      `file length ${bytes.length} does not match ${count} cards ` +
        `(expected ${expected} bytes)`,
    );
  }
  const deck: Card[] = [];
  let offset = HEADER_LENGTH;
  for (let card = 0; card < count; card++) {
    const columns = new Uint16Array(COLUMN_COUNT);
    for (let i = 0; i < COLUMN_COUNT; i += 2) {
      const b0 = bytes[offset];
      const b1 = bytes[offset + 1];
      const b2 = bytes[offset + 2];
      columns[i] = (b0 << 4) | (b1 >> 4);
      columns[i + 1] = ((b1 & 0xf) << 8) | b2;
      offset += 3;
    }
    deck.push(columns);
  }
  return deck;
}
