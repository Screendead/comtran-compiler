import * as path from 'node:path';
import * as vscode from 'vscode';

import { blankCard, encodeCanon } from './canonCodec';
import {
  canonPathFor,
  mirrorPathFor,
  pairBusy,
  repoRootFor,
  runDeckconv,
  withPair,
} from './deckSync';
import { registerManualCitationProviders } from './manualLinks';
import { PunchcardEditorProvider } from './punchcardEditor';

/** Registers the punchcard editor when VS Code opens a `.ctd` file, the
 * save sync that keeps a deck and its mirror fresh together, and the
 * manual-citation link and hover providers for `dart` files. */
export function activate(context: vscode.ExtensionContext): void {
  const provider = new PunchcardEditorProvider(context);
  context.subscriptions.push(provider.register());
  context.subscriptions.push(
    vscode.commands.registerCommand('comtran.newDeck', newDeck),
  );
  registerDeckSync(context, provider);
  noticeOnDeckMirror(context);
  registerManualCitationProviders(context);
}

export function deactivate(): void {
  // Nothing to clean up: the provider disposes with the subscriptions.
}

/**
 * Asks the user for a save location, writes a one-card canon deck there, and
 * opens it in the punchcard editor. There is otherwise no way to start a
 * deck from inside VS Code.
 */
async function newDeck(): Promise<void> {
  const uri = await vscode.window.showSaveDialog({
    filters: { 'COMTRAN deck': ['ctd'] },
    saveLabel: 'Create Deck',
  });
  if (uri === undefined) {
    return;
  }
  await vscode.workspace.fs.writeFile(uri, encodeCanon([blankCard()]));
  void regenMirror(uri);
  await vscode.commands.executeCommand(
    'vscode.openWith',
    uri,
    PunchcardEditorProvider.viewType,
  );
}

/** Wires the two save directions (`docs/design/deck-format.md` §6): a deck
 * save regenerates its `.ct` mirror, and a mirror save rewrites its deck
 * through `deckconv to-canon`. */
function registerDeckSync(
  context: vscode.ExtensionContext,
  provider: PunchcardEditorProvider,
): void {
  context.subscriptions.push(
    provider.onDidSaveDeck((uri) => void regenMirror(uri)),
    vscode.workspace.onDidSaveTextDocument((document) => {
      if (
        document.languageId === 'comtran-deck' &&
        document.uri.scheme === 'file'
      ) {
        void applyMirror(document.uri, provider);
      }
    }),
  );
}

/** Regenerates the `.ct` mirror after the deck at `uri` was written. */
async function regenMirror(uri: vscode.Uri): Promise<void> {
  if (uri.scheme !== 'file') {
    return;
  }
  const mirrorPath = mirrorPathFor(uri.fsPath);
  if (mirrorPath === null) {
    return;
  }
  const root = repoRootFor(uri.fsPath);
  if (root === null) {
    void vscode.window.showErrorMessage(
      `${path.basename(uri.fsPath)} is outside a Dart package; run ` +
        'deckconv regen on it yourself.',
    );
    return;
  }
  const result = await withPair(uri.fsPath, () =>
    runDeckconv(root, ['regen', uri.fsPath]),
  );
  if (!result.ok) {
    void vscode.window.showErrorMessage(
      `deckconv regen failed: ${result.detail}`,
    );
    return;
  }
  const dirty = vscode.workspace.textDocuments.find(
    (document) => document.uri.fsPath === mirrorPath && document.isDirty,
  );
  if (dirty !== undefined) {
    void vscode.window.showWarningMessage(
      `The deck save regenerated ${path.basename(mirrorPath)} on disk; ` +
        'the unsaved mirror edits are now stale. Revert them.',
    );
  }
}

/** Rewrites the deck from the mirror at `uri` through `deckconv to-canon`,
 * then reloads the open punchcard editor, if any. Punch edits outrank the
 * mirror text: a dirty or concurrently saved deck skips the apply, and
 * punch edits made while `to-canon` runs are kept, not reverted. */
async function applyMirror(
  uri: vscode.Uri,
  provider: PunchcardEditorProvider,
): Promise<void> {
  const canonPath = canonPathFor(uri.fsPath);
  if (canonPath === null) {
    return;
  }
  if (pairBusy(canonPath)) {
    void vscode.window.showWarningMessage(
      `A deckconv run on ${path.basename(canonPath)} is in progress; the ` +
        'mirror save was not applied. Save the mirror again.',
    );
    return;
  }
  if (deckEditorIsDirty(canonPath)) {
    void vscode.window.showWarningMessage(
      `${path.basename(canonPath)} is open with unsaved punch edits; the ` +
        'mirror save did not touch it. Save or revert the deck, then save ' +
        'the mirror again.',
    );
    return;
  }
  const root = repoRootFor(uri.fsPath);
  if (root === null) {
    void vscode.window.showErrorMessage(
      `${path.basename(uri.fsPath)} is outside a Dart package; run ` +
        'deckconv to-canon on it yourself.',
    );
    return;
  }
  await withPair(canonPath, async () => {
    const result = await runDeckconv(root, ['to-canon', uri.fsPath, canonPath]);
    if (!result.ok) {
      void vscode.window.showErrorMessage(
        `deckconv to-canon failed: ${result.detail}`,
      );
      return;
    }
    if (deckEditorIsDirty(canonPath)) {
      void vscode.window.showWarningMessage(
        `${path.basename(canonPath)} gained punch edits while the mirror ` +
          'save was applied; the editor keeps them. Saving the deck will ' +
          'overwrite the mirror edit.',
      );
      return;
    }
    await provider.documentFor(vscode.Uri.file(canonPath))?.revert();
  });
}

/** True when a punchcard editor tab on `fsPath` has unsaved edits. */
function deckEditorIsDirty(fsPath: string): boolean {
  for (const group of vscode.window.tabGroups.all) {
    for (const tab of group.tabs) {
      const input = tab.input as
        | { uri?: vscode.Uri; viewType?: string }
        | undefined
        | null;
      if (
        tab.isDirty &&
        input?.viewType === PunchcardEditorProvider.viewType &&
        input.uri?.fsPath === fsPath
      ) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Tells the user, once per session, what saving a `.ct` mirror does: the
 * extension runs `deckconv to-canon`, which rewrites the matching deck or
 * rejects text that is not in normal form.
 */
function noticeOnDeckMirror(context: vscode.ExtensionContext): void {
  let shown = false;
  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument((document) => {
      if (shown || document.languageId !== 'comtran-deck') {
        return;
      }
      shown = true;
      void vscode.window.showInformationMessage(
        'This .ct file is a generated mirror of the matching .ctd deck. ' +
          'Saving it rewrites the deck through deckconv to-canon; text ' +
          'that is not normal-form mirror text is rejected, and the deck ' +
          'stays unchanged.',
      );
    }),
  );
}
