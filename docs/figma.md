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
| Auto-layout frame, vertical | `vstack` (item spacing → `spacing`) |
| Auto-layout frame, horizontal | `hstack` (item spacing → `spacing`) |
| Other frame / group / component / instance | `vstack` |
| Text | `text` (characters → `value`, font size → `style`) |
| Rectangle / ellipse / vector | `image` (layer name → `name`) |
| Hidden layer | skipped |
| Anything else | empty `text` placeholder + a warning |

Font size picks the text style: ≥28 → `title`, ≥20 → `headline`, ≥15 → `body`,
otherwise `caption`.

## Actions and tokens

Actions have no Figma equivalent, so a button and its action come from the layer
name, formatted `type:verb:target`:

| Layer name | Result |
| --- | --- |
| `button:navigate:productDetail` | button with a `navigate` action to the `productDetail` screen |
| `button:api:getBalance` | button with an `api` action calling the `getBalance` request |
| `button:openurl:supportChat` | button with an `openURL` action to the named `supportChat` link |
| `button:dismiss`, `button:refresh` | button with that action |
| `card`, `vstack`, `hstack`, `text`, `image` | forces that node type |

A button's title is its first text layer, falling back to the target, then the layer
name. A button whose action has no valid target keeps the button but drops the
action (with a warning).

Data tokens are authored literally: text such as `Hello, {{user.name}}` is copied
through verbatim and resolved by the app at render time.
