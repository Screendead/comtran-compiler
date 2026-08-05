import * as vscode from 'vscode';

import { blankCard, encodeCanon } from './canonCodec';
import { registerManualCitationProviders } from './manualLinks';
import { PunchcardEditorProvider } from './punchcardEditor';

/** Registers the punchcard editor when VS Code opens a `.ctd` file, and
 * the manual-citation link and hover providers for `dart` files. */
export function activate(context: vscode.ExtensionContext): void {
  context.subscriptions.push(PunchcardEditorProvider.register(context));
  context.subscriptions.push(
    vscode.commands.registerCommand('comtran.newDeck', newDeck),
  );
  warnOnDeckMirror(context);
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
  await vscode.commands.executeCommand(
    'vscode.openWith',
    uri,
    PunchcardEditorProvider.viewType,
  );
}

/**
 * Tells the user, once per session, that a `.ct` file is a generated
 * mirror: `deckconv` writes it from the matching `.ctd` file, and the
 * punchcard editor never writes it back.
 */
function warnOnDeckMirror(context: vscode.ExtensionContext): void {
  let warned = false;
  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument((document) => {
      if (warned || document.languageId !== 'comtran-deck') {
        return;
      }
      warned = true;
      void vscode.window.showInformationMessage(
        'This .ct file is a generated mirror of the matching .ctd ' +
          'file. deckconv writes it; edits here are not saved back to the ' +
          'deck.',
      );
    }),
  );
}
