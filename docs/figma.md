# Figma export

The Figma plugin in [`figma-plugin/`](https://github.com/iQbalADR/murti/tree/main/figma-plugin)
turns the selected frame into a validated Murti payload, so a design can become a
Murti screen without writing JSON by hand. It targets `murti.schema.json` directly,
and its tests validate every mapping against that schema.

The mapping is lossy by design: Murti has a closed component vocabulary, so only the
layers that map to a component are exported. Anything else produces a warning.

## Build and load

Requires Node 18+.

```sh
cd figma-plugin
npm install
npm run build
```

In the Figma desktop app: **Plugins → Development → Import plugin from manifest…**
and pick `figma-plugin/manifest.json`. Select a frame and run the plugin; the panel
shows the JSON to copy, plus any warnings.

## How layers map

| Figma layer | Murti node |
| --- | --- |
| Auto-layout frame, vertical | `vstack` (item spacing → `spacing`, cross-axis alignment → `alignment`) |
| Auto-layout frame, horizontal | `hstack` (item spacing → `spacing`, cross-axis alignment → `alignment`) |
| Frame with a solid fill and rounded corners | `card` (auto-layout padding → `padding`) |
| Frame without auto-layout, or a group | `zstack` (frame size + each child's `x`/`y`/`width`/`height`) |
| Text | `text` (characters → `value`; named text style, else font size → `style`) |
| Rectangle / ellipse / vector | `image` (layer name → `name`; image-fill scale `FILL` → `contentMode: fill`) |
| Hidden layer | skipped |
| Anything else | empty `text` placeholder + a warning |

The text style comes from the layer's named text style when its name contains
`title`, `heading`, `caption`, or `body`; otherwise font size decides: ≥28 →
`title`, ≥20 → `headline`, ≥15 → `body`, otherwise `caption`.

Visual style is captured into the [bounded style props](schema.md#style-props): a
solid fill → `background`, a corner radius → `cornerRadius`, a text layer's fill →
`color`, and its font style → `weight`. So an exported screen carries its colors and
type weights, not just its structure.

## Embedding images

By design a payload references images by name/source, not by pixels — so an export
gives you the image *slots*, and the app supplies the real photos. For a pixel
preview, tick **Embed images** in the plugin: image-like layers (photos, icons,
vectors) are rendered to PNG/JPG and inlined as a `data:` URL in the image's `url`,
so the export renders exactly like Figma without any assets in the app.

This is a preview aid only. Embedded pixels make the JSON much larger and blow past
the payload's [size bounds](schema.md#bounds), so an embedded export isn't a valid
production payload — ship images as named sources or URLs your app resolves.

## Actions and tokens

Actions have no Figma equivalent, so a button and its action come from the layer
name, formatted `type:verb:target`:

| Layer name | Result |
| --- | --- |
| `button:navigate:productDetail` | button with a `navigate` action to the `productDetail` screen |
| `button:api:getBalance` | button with an `api` action calling the `getBalance` request |
| `button:openurl:supportChat` | button with an `openURL` action to the named `supportChat` link |
| `button:dismiss`, `button:refresh` | button with that action |
| `image:systemName:star.fill` | image rendering the `star.fill` SF Symbol |
| `card`, `vstack`, `hstack`, `text`, `image` | forces that node type |

A button's title is its first text layer, falling back to the target, then the layer
name. A button whose action has no valid target keeps the button but drops the
action (with a warning). The convention is read from the layer name, or, for a
renamed component instance, from its main component's name.

Data tokens are authored literally: text such as `Hello, {{user.name}}` is copied
through verbatim and resolved by the app at render time.
