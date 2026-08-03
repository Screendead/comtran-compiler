import * as vscode from 'vscode';

import { PunchcardEditorProvider } from './punchcardEditor';

/** Registers the punchcard editor when VS Code opens a `.ctdeck` file. */
export function activate(context: vscode.ExtensionContext): void {
  context.subscriptions.push(PunchcardEditorProvider.register(context));
}

export function deactivate(): void {
  // Nothing to clean up: the provider disposes with the subscriptions.
}
