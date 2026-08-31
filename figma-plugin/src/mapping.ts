// Maps a Figma layer tree to a Murti SDUI payload. Kept free of the Figma plugin
// API so it can be unit-tested with plain objects; `code.ts` reads the real
// document into `FigmaInput` and calls in here.

export type MurtiValue =
  | string
  | number
  | boolean
  | null
  | MurtiValue[]
  | { [key: string]: MurtiValue };

export interface MurtiAction {
  type: "navigate" | "api" | "dismiss" | "refresh" | "openURL";
  screen?: string;
  request?: string;
  link?: string;
  params?: Record<string, MurtiValue>;
  onSuccess?: MurtiAction;
  onError?: MurtiAction;
}

export interface MurtiNode {
  type: string;
  id?: string;
  props?: Record<string, MurtiValue>;
  children?: MurtiNode[];
  action?: MurtiAction;
}

export interface MurtiPayload {
  schemaVersion: string;
  screen: { key: string; root: MurtiNode };
}

/// The subset of a Figma node the mapping needs. `code.ts` fills this in from the
/// real `SceneNode`.
export interface FigmaInput {
  type: string;
  name: string;
  visible?: boolean;
  layoutMode?: "NONE" | "HORIZONTAL" | "VERTICAL" | "GRID";
  itemSpacing?: number;
  characters?: string;
  fontSize?: number;
  children?: FigmaInput[];
}

export interface MapOptions {
  schemaVersion?: string;
}

export interface MapResult {
  payload: MurtiPayload;
  warnings: string[];
}

const TYPE_KEYWORDS = new Set(["text", "image", "button", "card", "vstack", "hstack"]);
const CONTAINER_FIGMA = new Set(["FRAME", "GROUP", "COMPONENT", "INSTANCE", "COMPONENT_SET", "SECTION"]);
const GRAPHIC_FIGMA = new Set(["RECTANGLE", "ELLIPSE", "VECTOR", "LINE", "STAR", "POLYGON", "BOOLEAN_OPERATION"]);

/// Map a selected frame to a full payload, defaulting the schema version and
/// deriving the screen key from the frame name.
export function mapPayload(root: FigmaInput, options: MapOptions = {}): MapResult {
  const warnings: string[] = [];
  const key = sanitizeIdentifier(root.name) ?? "screen";
  const node = mapNode(root, warnings) ?? { type: "vstack" };
  return {
    payload: {
      schemaVersion: options.schemaVersion ?? "1.0",
      screen: { key, root: node },
    },
    warnings,
  };
}

/// Map one Figma node to a Murti node. Returns `null` for a hidden layer (the
/// caller drops it). A layer name may force the type and, for buttons, the action
/// via a `type:verb:target` convention; otherwise the Figma node type decides.
export function mapNode(node: FigmaInput, warnings: string[]): MurtiNode | null {
  if (node.visible === false) return null;

  const convention = parseConvention(node.name);
  switch (convention.type) {
    case "button":
      return mapButton(node, convention, warnings);
    case "text":
      return mapText(node);
    case "image":
      return mapImage(node);
    case "card":
      return mapContainer(node, "card", warnings);
    case "vstack":
    case "hstack":
      return mapContainer(node, convention.type, warnings);
  }

  if (node.type === "TEXT") return mapText(node);
  if (CONTAINER_FIGMA.has(node.type)) return mapContainer(node, stackTypeFor(node), warnings);
  if (GRAPHIC_FIGMA.has(node.type)) return mapImage(node);

  warnings.push(`Unsupported layer "${node.name}" (${node.type}) exported as an empty text placeholder.`);
  return { type: "text", props: { value: "" } };
}

function mapText(node: FigmaInput): MurtiNode {
  const props: Record<string, MurtiValue> = { value: node.characters ?? "" };
  const style = styleForFontSize(node.fontSize);
  if (style) props.style = style;
  return { type: "text", props };
}

function mapImage(node: FigmaInput): MurtiNode {
  return { type: "image", props: { name: node.name.trim() } };
}

function mapContainer(node: FigmaInput, type: "vstack" | "hstack" | "card", warnings: string[]): MurtiNode {
  const result: MurtiNode = { type };
  if (type !== "card" && typeof node.itemSpacing === "number") {
    result.props = { spacing: node.itemSpacing };
  }
  const children = mapChildren(node, warnings);
  if (children.length > 0) result.children = children;
  return result;
}

function mapButton(node: FigmaInput, convention: Convention, warnings: string[]): MurtiNode {
  const title = firstTextValue(node) ?? convention.target ?? node.name;
  const result: MurtiNode = { type: "button", props: { title } };
  const action = buttonAction(convention, node.name, warnings);
  if (action) result.action = action;
  return result;
}

function mapChildren(node: FigmaInput, warnings: string[]): MurtiNode[] {
  return (node.children ?? [])
    .map((child) => mapNode(child, warnings))
    .filter((child): child is MurtiNode => child !== null);
}

interface Convention {
  type?: string;
  verb?: string;
  target?: string;
}

function parseConvention(name: string): Convention {
  const parts = name.split(":").map((part) => part.trim());
  const head = parts[0]?.toLowerCase();
  if (head && TYPE_KEYWORDS.has(head)) {
    return { type: head, verb: parts[1]?.toLowerCase(), target: parts[2] };
  }
  return {};
}

function buttonAction(convention: Convention, name: string, warnings: string[]): MurtiAction | undefined {
  const target = convention.target ? sanitizeIdentifier(convention.target) : null;
  switch (convention.verb) {
    case "navigate":
      if (!target) return dropAction(name, "navigate", warnings);
      return { type: "navigate", screen: target };
    case "api":
      if (!target) return dropAction(name, "api", warnings);
      return { type: "api", request: target };
    case "openurl":
      if (!target) return dropAction(name, "openURL", warnings);
      return { type: "openURL", link: target };
    case "dismiss":
      return { type: "dismiss" };
    case "refresh":
      return { type: "refresh" };
    default:
      return undefined;
  }
}

function dropAction(name: string, verb: string, warnings: string[]): undefined {
  warnings.push(`Button "${name}" has a "${verb}" action without a valid target; the action was dropped.`);
  return undefined;
}

function stackTypeFor(node: FigmaInput): "vstack" | "hstack" {
  return node.layoutMode === "HORIZONTAL" ? "hstack" : "vstack";
}

function styleForFontSize(size?: number): string | undefined {
  if (typeof size !== "number") return undefined;
  if (size >= 28) return "title";
  if (size >= 20) return "headline";
  if (size >= 15) return "body";
  return "caption";
}

function firstTextValue(node: FigmaInput): string | undefined {
  if (node.type === "TEXT" && node.characters) return node.characters;
  for (const child of node.children ?? []) {
    const found = firstTextValue(child);
    if (found) return found;
  }
  return undefined;
}

/// Reduce an arbitrary layer name to a Murti identifier (`^[A-Za-z][A-Za-z0-9_]*$`),
/// or `null` when nothing usable remains.
function sanitizeIdentifier(raw: string): string | null {
  const cleaned = raw.replace(/[^A-Za-z0-9_]/g, "");
  const match = cleaned.match(/^[A-Za-z][A-Za-z0-9_]*/);
  return match ? match[0].slice(0, 128) : null;
}
