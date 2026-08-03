import * as vscode from 'vscode';

import { COLUMN_COUNT, blankCard } from './canonCodec';
import {
  MARKER_NONE,
  MARKER_SPECIAL,
  MARKER_UNATTESTED,
  classifyCards,
  fieldsFor,
  previewOf,
  readCard,
} from './cardView';
import { DIVISION_FIELDS, GENERIC_FIELDS } from './columns';
import { bcdFromGlyph, punchesFromBcd } from './charCode';
import { DeckChange, PunchcardDocument } from './punchcardDocument';

interface PanelState {
  /** The card the webview shows. */
  index: number;
  /** The document structure revision this webview last saw. */
  structure: number;
}

/** The punch-level editor for `.ctdeck` files. */
export class PunchcardEditorProvider
  implements vscode.CustomEditorProvider<PunchcardDocument>
{
  public static readonly viewType = 'comtran.punchcard';

  public static register(context: vscode.ExtensionContext): vscode.Disposable {
    return vscode.window.registerCustomEditorProvider(
      PunchcardEditorProvider.viewType,
      new PunchcardEditorProvider(context),
      {
        webviewOptions: { retainContextWhenHidden: true },
        supportsMultipleEditorsPerDocument: false,
      },
    );
  }

  constructor(private readonly context: vscode.ExtensionContext) {}

  private readonly panels = new Map<vscode.WebviewPanel, PanelState>();
  private readonly panelsByDocument = new Map<
    PunchcardDocument,
    Set<vscode.WebviewPanel>
  >();

  private readonly _onDidChangeCustomDocument = new vscode.EventEmitter<
    vscode.CustomDocumentEditEvent<PunchcardDocument>
  >();

  public readonly onDidChangeCustomDocument =
    this._onDidChangeCustomDocument.event;

  public async openCustomDocument(
    uri: vscode.Uri,
    openContext: vscode.CustomDocumentOpenContext,
    _token: vscode.CancellationToken,
  ): Promise<PunchcardDocument> {
    const document = await PunchcardDocument.create(uri, openContext.backupId);
    document.onDidChange((edit) => {
      this._onDidChangeCustomDocument.fire({
        document,
        label: edit.label,
        undo: () => edit.undo(),
        redo: () => edit.redo(),
      });
    });
    document.onDidChangeContent((change) => {
      this.refresh(document, change);
    });
    return document;
  }

  public async resolveCustomEditor(
    document: PunchcardDocument,
    panel: vscode.WebviewPanel,
    _token: vscode.CancellationToken,
  ): Promise<void> {
    this.panels.set(panel, { index: 0, structure: -1 });
    let set = this.panelsByDocument.get(document);
    if (set === undefined) {
      set = new Set();
      this.panelsByDocument.set(document, set);
    }
    set.add(panel);

    panel.webview.options = { enableScripts: true, localResourceRoots: [] };
    panel.webview.html = await this.html();

    panel.onDidDispose(() => {
      this.panels.delete(panel);
      const siblings = this.panelsByDocument.get(document);
      siblings?.delete(panel);
      if (siblings !== undefined && siblings.size === 0) {
        this.panelsByDocument.delete(document);
      }
    });

    panel.webview.onDidReceiveMessage((message) => {
      try {
        this.onMessage(document, panel, message);
      } catch (error) {
        this.status(panel, `${error instanceof Error ? error.message : error}`);
      }
    });
  }

  public saveCustomDocument(
    document: PunchcardDocument,
    cancellation: vscode.CancellationToken,
  ): Thenable<void> {
    return document.save(cancellation);
  }

  public saveCustomDocumentAs(
    document: PunchcardDocument,
    destination: vscode.Uri,
    cancellation: vscode.CancellationToken,
  ): Thenable<void> {
    return document.saveAs(destination, cancellation);
  }

  public revertCustomDocument(document: PunchcardDocument): Thenable<void> {
    return document.revert();
  }

  public backupCustomDocument(
    document: PunchcardDocument,
    context: vscode.CustomDocumentBackupContext,
    cancellation: vscode.CancellationToken,
  ): Thenable<vscode.CustomDocumentBackup> {
    return document.backup(context.destination, cancellation);
  }

  // --- messages -----------------------------------------------------------

  private onMessage(
    document: PunchcardDocument,
    panel: vscode.WebviewPanel,
    message: { type: string; [key: string]: unknown },
  ): void {
    const state = this.panels.get(panel);
    if (state === undefined) {
      return;
    }
    switch (message.type) {
      case 'ready':
        this.send(document, panel, { force: true });
        return;
      case 'select':
        state.index = this.clamp(document, Number(message.index));
        this.send(document, panel, {});
        return;
      case 'toggle':
        document.togglePunch(
          this.clamp(document, Number(message.index)),
          Number(message.column),
          Number(message.row),
        );
        return;
      case 'setColumn':
        document.setColumn(
          this.clamp(document, Number(message.index)),
          Number(message.column),
          Number(message.punches),
        );
        return;
      case 'typeGlyph':
        this.typeGlyph(document, panel, message);
        return;
      case 'insert':
      case 'duplicate': {
        const at = document.cardCount === 0 ? 0 : Number(message.index) + 1;
        const source =
          message.type === 'duplicate' && document.cardCount > 0
            ? document.card(this.clamp(document, Number(message.index)))
            : blankCard();
        state.index = at;
        document.insertCard(at, source);
        return;
      }
      case 'delete': {
        if (document.cardCount === 0) {
          return;
        }
        const at = this.clamp(document, Number(message.index));
        state.index = Math.max(0, Math.min(at, document.cardCount - 2));
        document.deleteCard(at);
        return;
      }
      default:
        return;
    }
  }

  private typeGlyph(
    document: PunchcardDocument,
    panel: vscode.WebviewPanel,
    message: { [key: string]: unknown },
  ): void {
    const index = this.clamp(document, Number(message.index));
    const column = Number(message.column);
    const glyph = String(message.glyph).toUpperCase();
    const bcd = bcdFromGlyph(glyph);
    const punches = bcd === null ? null : punchesFromBcd(bcd);
    if (punches === null) {
      this.status(panel, `'${glyph}' is not a Set H source character`);
      return;
    }
    document.typeColumn(index, column, punches);
    this.send(document, panel, {
      cursor: Math.min(column + 1, COLUMN_COUNT),
    });
  }

  // --- webview updates ----------------------------------------------------

  private refresh(document: PunchcardDocument, change: DeckChange): void {
    for (const panel of this.panelsByDocument.get(document) ?? []) {
      const state = this.panels.get(panel);
      if (state === undefined) {
        continue;
      }
      state.index = this.clamp(document, state.index);
      this.send(document, panel, { changed: change.cardIndex });
    }
  }

  private send(
    document: PunchcardDocument,
    panel: vscode.WebviewPanel,
    options: { force?: boolean; changed?: number | null; cursor?: number },
  ): void {
    const state = this.panels.get(panel);
    if (state === undefined) {
      return;
    }
    const structural =
      options.force === true || state.structure !== document.structureRevision;
    state.structure = document.structureRevision;
    state.index = this.clamp(document, state.index);
    const index = state.index;
    const card = document.cardCount > 0 ? document.card(index) : null;
    const changed = options.changed;
    const kinds = classifyCards(document.deck);
    void panel.webview.postMessage({
      type: 'state',
      cardCount: document.cardCount,
      index,
      previews: structural
        ? document.deck.map((c) => previewOf(c))
        : null,
      preview:
        !structural && typeof changed === 'number' && changed < document.cardCount
          ? { index: changed, text: previewOf(document.card(changed)) }
          : null,
      columns: card === null ? [] : Array.from(card),
      readout: card === null ? [] : readCard(card),
      cursor: options.cursor ?? null,
      kinds,
      tables: { generic: GENERIC_FIELDS, ...DIVISION_FIELDS },
      fields: fieldsFor(card === null ? 'blank' : kinds[index]),
      markers: {
        special: MARKER_SPECIAL,
        unattested: MARKER_UNATTESTED,
        none: MARKER_NONE,
      },
    });
  }

  private status(panel: vscode.WebviewPanel, text: string): void {
    void panel.webview.postMessage({ type: 'status', text });
  }

  private clamp(document: PunchcardDocument, index: number): number {
    if (!Number.isFinite(index)) {
      return 0;
    }
    return Math.max(0, Math.min(Math.trunc(index), document.cardCount - 1));
  }

  // --- html ---------------------------------------------------------------

  private async html(): Promise<string> {
    const nonce = nonceOf();
    const css = await this.read('punchcard.css');
    const script = await this.read('punchcard.js');
    const csp = [
      "default-src 'none'",
      `style-src 'nonce-${nonce}'`,
      `script-src 'nonce-${nonce}'`,
    ].join('; ');
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="${csp};">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>COMTRAN Punchcard</title>
<style nonce="${nonce}">
${css}
</style>
</head>
<body>
<div class="app">
  <div class="side">
    <div class="side-head" id="deckHead">Deck</div>
    <ol class="cards" id="cardList"></ol>
  </div>
  <div class="main">
    <div class="toolbar">
      <button type="button" id="btnPrev" title="Previous card">&#9664;</button>
      <span class="pos" id="cardPos">-</span>
      <button type="button" id="btnNext" title="Next card">&#9654;</button>
      <span class="gap"></span>
      <button type="button" id="btnAdd">Add card</button>
      <button type="button" id="btnDup">Duplicate</button>
      <button type="button" id="btnDel">Delete</button>
      <span class="gap"></span>
      <label class="mode"><input type="checkbox" id="typeMode"> Type to punch</label>
      <span class="gap"></span>
      <button type="button" id="zoomOut" title="Narrower">&#8722;</button>
      <button type="button" id="zoomIn" title="Wider">&#43;</button>
    </div>
    <div class="cardwrap" id="cardWrap" tabindex="0">
      <div class="card" id="card">
        <div class="band ruler" id="fields"></div>
        <div class="band interp" id="interp"></div>
        <div class="band nums" id="numsTens"></div>
        <div class="band nums" id="numsUnits"></div>
        <div class="grid" id="grid"></div>
      </div>
      <p class="empty hidden" id="empty">The deck has no cards. Use "Add card".</p>
    </div>
    <div class="status" id="status">-</div>
    <div class="legend" id="legend"></div>
  </div>
</div>
<script nonce="${nonce}">
${script}
</script>
</body>
</html>`;
  }

  private async read(name: string): Promise<string> {
    const uri = vscode.Uri.joinPath(this.context.extensionUri, 'media', name);
    const bytes = await vscode.workspace.fs.readFile(uri);
    return new TextDecoder().decode(bytes);
  }
}

function nonceOf(): string {
  const chars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let text = '';
  for (let i = 0; i < 32; i++) {
    text += chars[Math.floor(Math.random() * chars.length)];
  }
  return text;
}
