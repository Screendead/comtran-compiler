import * as vscode from 'vscode';

import {
  Card,
  COLUMN_COUNT,
  blankCard,
  copyCard,
  decodeCanon,
  encodeCanon,
} from './canonCodec';

/** What changed in the deck, for the webviews. */
export interface DeckChange {
  /** True when cards were added or removed, or the whole deck was replaced. */
  readonly structural: boolean;
  /** The card that changed, or `null` for a whole-deck change. */
  readonly cardIndex: number | null;
}

/** An undoable edit, as VS Code's undo stack wants it. */
export interface DeckEdit {
  readonly label: string;
  undo(): void;
  redo(): void;
}

/**
 * An open `.ctdeck` file: the deck in memory, plus the edit and change events
 * that drive VS Code's undo stack and the webviews.
 */
export class PunchcardDocument implements vscode.CustomDocument {
  private constructor(
    public readonly uri: vscode.Uri,
    deck: Card[],
  ) {
    this._deck = deck;
  }

  private _deck: Card[];
  private _structureRevision = 0;
  private _disposed = false;

  private readonly _onDidChange = new vscode.EventEmitter<DeckEdit>();

  /** Fires for every user edit; the provider forwards it to VS Code. */
  public readonly onDidChange = this._onDidChange.event;

  private readonly _onDidChangeContent = new vscode.EventEmitter<DeckChange>();

  /** Fires whenever the deck contents change, undo and revert included. */
  public readonly onDidChangeContent = this._onDidChangeContent.event;

  /** Opens `uri`, or `backupId` when VS Code restores a hot exit backup. */
  public static async create(
    uri: vscode.Uri,
    backupId: string | undefined,
  ): Promise<PunchcardDocument> {
    const source = backupId !== undefined ? vscode.Uri.parse(backupId) : uri;
    const deck = await PunchcardDocument.readDeck(source, source.scheme);
    return new PunchcardDocument(uri, deck);
  }

  private static async readDeck(
    source: vscode.Uri,
    scheme: string,
  ): Promise<Card[]> {
    if (scheme === 'untitled') {
      return [blankCard()];
    }
    const bytes = await vscode.workspace.fs.readFile(source);
    if (bytes.length === 0) {
      // A file created outside the editor (touch, the OS file explorer) has
      // no header yet. Treat it as an empty deck instead of failing to open;
      // the first save writes a real 12-byte header.
      return [];
    }
    return decodeCanon(bytes);
  }

  /** The number of cards in the deck. */
  public get cardCount(): number {
    return this._deck.length;
  }

  /** Counts up on every structural change, so a webview can spot one. */
  public get structureRevision(): number {
    return this._structureRevision;
  }

  /** The card at `index`. Do not modify the result. */
  public card(index: number): Card {
    return this._deck[index];
  }

  /** The whole deck. Do not modify the result. */
  public get deck(): readonly Card[] {
    return this._deck;
  }

  /** The canon bytes of the deck as it stands. */
  public bytes(): Uint8Array {
    return encodeCanon(this._deck);
  }

  private apply(
    label: string,
    change: DeckChange,
    redo: () => void,
    undo: () => void,
  ): void {
    redo();
    this._onDidChangeContent.fire(change);
    this._onDidChange.fire({
      label,
      undo: () => {
        undo();
        this._onDidChangeContent.fire(change);
      },
      redo: () => {
        redo();
        this._onDidChangeContent.fire(change);
      },
    });
  }

  /** Sets one column's punch pattern (`column` is 1-based). */
  public setColumn(index: number, column: number, punches: number): void {
    this.checkCardIndex(index);
    if (!Number.isInteger(column) || column < 1 || column > COLUMN_COUNT) {
      throw new RangeError(`column ${column} is not in the range 1..80`);
    }
    if (!Number.isInteger(punches) || punches < 0 || punches > 0xfff) {
      throw new RangeError(`punches ${punches} does not fit 12 bits`);
    }
    const before = this._deck[index][column - 1];
    if (before === punches) {
      return;
    }
    const change: DeckChange = { structural: false, cardIndex: index };
    this.apply(
      'punch column',
      change,
      () => {
        this._deck[index][column - 1] = punches;
      },
      () => {
        this._deck[index][column - 1] = before;
      },
    );
  }

  /** Toggles one punch row (`row` is 0 for row 12 down to 11 for row 9). */
  public togglePunch(index: number, column: number, row: number): void {
    if (!Number.isInteger(row) || row < 0 || row > 11) {
      throw new RangeError(`row ${row} is not in the range 0..11`);
    }
    const bit = 1 << (11 - row);
    this.setColumn(index, column, this._deck[index][column - 1] ^ bit);
  }

  /** Inserts `card` at `index`, which may be the end of the deck. */
  public insertCard(index: number, card: Card): void {
    if (!Number.isInteger(index) || index < 0 || index > this._deck.length) {
      throw new RangeError(`insert index ${index} is out of range`);
    }
    const copy = copyCard(card);
    const change: DeckChange = { structural: true, cardIndex: index };
    this.apply(
      'insert card',
      change,
      () => {
        this._deck.splice(index, 0, copy);
        this._structureRevision++;
      },
      () => {
        this._deck.splice(index, 1);
        this._structureRevision++;
      },
    );
  }

  /** Removes the card at `index`. */
  public deleteCard(index: number): void {
    this.checkCardIndex(index);
    const removed = copyCard(this._deck[index]);
    const change: DeckChange = { structural: true, cardIndex: index };
    this.apply(
      'delete card',
      change,
      () => {
        this._deck.splice(index, 1);
        this._structureRevision++;
      },
      () => {
        this._deck.splice(index, 0, removed);
        this._structureRevision++;
      },
    );
  }

  /** Writes the deck to its own file. */
  public async save(cancellation: vscode.CancellationToken): Promise<void> {
    await this.saveAs(this.uri, cancellation);
  }

  /** Writes the deck to `target`. */
  public async saveAs(
    target: vscode.Uri,
    cancellation: vscode.CancellationToken,
  ): Promise<void> {
    const data = this.bytes();
    if (cancellation.isCancellationRequested) {
      return;
    }
    await vscode.workspace.fs.writeFile(target, data);
  }

  /** Reloads the deck from disk. */
  public async revert(): Promise<void> {
    this._deck = await PunchcardDocument.readDeck(this.uri, this.uri.scheme);
    this._structureRevision++;
    this._onDidChangeContent.fire({ structural: true, cardIndex: null });
  }

  /** Writes a hot exit backup to `destination`. */
  public async backup(
    destination: vscode.Uri,
    cancellation: vscode.CancellationToken,
  ): Promise<vscode.CustomDocumentBackup> {
    await this.saveAs(destination, cancellation);
    return {
      id: destination.toString(),
      delete: async () => {
        try {
          await vscode.workspace.fs.delete(destination);
        } catch {
          // The backup is already gone; nothing to do.
        }
      },
    };
  }

  private checkCardIndex(index: number): void {
    if (!Number.isInteger(index) || index < 0 || index >= this._deck.length) {
      throw new RangeError(`card index ${index} is out of range`);
    }
  }

  public dispose(): void {
    if (this._disposed) {
      return;
    }
    this._disposed = true;
    this._onDidChange.dispose();
    this._onDidChangeContent.dispose();
  }
}
