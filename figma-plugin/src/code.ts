// Figma plugin entry point. Reads the selected frame into the plain `FigmaInput`
// shape, maps it to a Murti payload, and shows the JSON in the panel. The mapping
// itself lives in `mapping.ts` so it can be unit-tested without the Figma runtime.

import { mapPayload, type FigmaInput } from "./mapping";

figma.showUI(__html__, { width: 440, height: 560, themeColors: true });

function toInput(node: SceneNode): FigmaInput {
  const input: FigmaInput = { type: node.type, name: node.name, visible: node.visible };

  if ("layoutMode" in node) {
    input.layoutMode = node.layoutMode;
    if (node.layoutMode === "HORIZONTAL" || node.layoutMode === "VERTICAL") {
      input.itemSpacing = node.itemSpacing;
    }
  }
  if (node.type === "TEXT") {
    input.characters = node.characters;
    if (typeof node.fontSize === "number") input.fontSize = node.fontSize;
  }
  if ("children" in node) {
    input.children = node.children.map(toInput);
  }
  return input;
}

function run(): void {
  const selection = figma.currentPage.selection;
  if (selection.length !== 1) {
    figma.ui.postMessage({ error: "Select exactly one frame to export." });
    return;
  }
  const { payload, warnings } = mapPayload(toInput(selection[0]));
  figma.ui.postMessage({ json: JSON.stringify(payload, null, 2), warnings });
}

run();
figma.on("selectionchange", run);

figma.ui.onmessage = (message: { type?: string }) => {
  if (message.type === "close") figma.closePlugin();
};
