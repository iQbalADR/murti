// Figma plugin entry point. Reads the selected frame into the plain `FigmaInput`
// shape, maps it to a Murti payload, and shows the JSON in the panel. The mapping
// itself lives in `mapping.ts` so it can be unit-tested without the Figma runtime.

import { mapPayload, type FigmaInput } from "./mapping";

figma.showUI(__html__, { width: 440, height: 560, themeColors: true });

function solidFillHex(node: SceneNode): string | undefined {
  if (!("fills" in node) || !Array.isArray(node.fills)) return undefined;
  const paint = node.fills.find((p) => p.type === "SOLID" && p.visible !== false);
  if (!paint || paint.type !== "SOLID") return undefined;
  const channel = (value: number) => Math.round(value * 255).toString(16).padStart(2, "0").toUpperCase();
  let hex = "#" + channel(paint.color.r) + channel(paint.color.g) + channel(paint.color.b);
  const opacity = paint.opacity ?? 1;
  if (opacity < 1) hex += channel(opacity);
  return hex;
}

function imageFillScaleMode(node: SceneNode): string | undefined {
  if (!("fills" in node) || !Array.isArray(node.fills)) return undefined;
  const fill = node.fills.find((paint) => paint.type === "IMAGE" && paint.visible !== false);
  return fill && fill.type === "IMAGE" ? fill.scaleMode : undefined;
}

async function toInput(node: SceneNode): Promise<FigmaInput> {
  const input: FigmaInput = { type: node.type, name: node.name, visible: node.visible };

  if ("layoutMode" in node) {
    input.layoutMode = node.layoutMode;
    if (node.layoutMode === "HORIZONTAL" || node.layoutMode === "VERTICAL") {
      input.itemSpacing = node.itemSpacing;
      input.counterAxisAlignItems = node.counterAxisAlignItems;
      input.padding = node.paddingTop;
    }
  }
  if ("cornerRadius" in node && typeof node.cornerRadius === "number") {
    input.cornerRadius = node.cornerRadius;
  }

  const fill = solidFillHex(node);
  if (fill) {
    if (node.type === "TEXT") input.textColor = fill;
    else input.fillColor = fill;
  }

  const scaleMode = imageFillScaleMode(node);
  if (scaleMode) input.imageScaleMode = scaleMode;

  if (node.type === "TEXT") {
    input.characters = node.characters;
    if (typeof node.fontSize === "number") input.fontSize = node.fontSize;
    if (node.fontName !== figma.mixed) input.fontStyle = node.fontName.style;
    if (typeof node.textStyleId === "string" && node.textStyleId !== "") {
      const style = await figma.getStyleByIdAsync(node.textStyleId);
      if (style) input.textStyleName = style.name;
    }
  }
  if (node.type === "INSTANCE") {
    const main = await node.getMainComponentAsync();
    if (main) input.mainComponentName = main.name;
  }
  if ("children" in node) {
    input.children = await Promise.all(node.children.map(toInput));
  }
  return input;
}

async function run(): Promise<void> {
  const selection = figma.currentPage.selection;
  if (selection.length !== 1) {
    figma.ui.postMessage({ error: "Select exactly one frame to export." });
    return;
  }
  const { payload, warnings } = mapPayload(await toInput(selection[0]));
  figma.ui.postMessage({ json: JSON.stringify(payload, null, 2), warnings });
}

void run();
figma.on("selectionchange", () => void run());

figma.ui.onmessage = (message: { type?: string }) => {
  if (message.type === "close") figma.closePlugin();
};
