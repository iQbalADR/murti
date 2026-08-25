# Contributing to Murti

Thanks for helping! Murti is built so that most changes are **one small file**.

## Extend by one file

- **New component** — one `MurtiComponent` type, or one inline
  `factory.register("type") { node, context in … }` call.
- **New screen** — a JSON payload + one `MurtiScreenFactory` entry. Never a class
  per screen.
- **New library integration** — a small adapter conforming to the relevant port
  (`MurtiNetworkClient`, `MurtiSignatureVerifier`, …). Networking adapters live in
  your app, not in this repo — see [docs/networking.md](docs/networking.md).

The action vocabulary is **closed** (navigate / api / dismiss / refresh / openURL);
adding an action type is a deliberate core change, not a routine PR.

## Build & test

```
swift build
swift test
```

Keep the suite green and add tests with your change.

## Schema fixtures

The authoritative schema is [docs/murti.schema.json](docs/murti.schema.json). If you
touch the payload shape, add matching fixtures under `docs/fixtures/valid/` and
`docs/fixtures/invalid/` (each invalid one demonstrates the rule that rejects it),
then run the lint:

```
python3 scripts/lint_schema.py
```

Valid fixtures must pass; invalid ones must fail for the stated reason. This keeps
the JSON Schema, the example payloads, and the Swift model in sync.

## Code style

- **Comments are documentation only** — what the code does and non-obvious *why*,
  present tense. No roadmap, version references, or "future / for now" notes.
- Match the surrounding code's naming and idiom. Public types carry the `Murti`
  prefix; small conforming types (components, commands) use short descriptive names.
- Swift 6 strict-concurrency clean.

## Commits

Commit messages are authored by the human contributor only — no tool-attribution
lines and no automated `Co-Authored-By` trailers.
