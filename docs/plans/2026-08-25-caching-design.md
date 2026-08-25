# MurtiCache — design

**Date:** 2026-08-25 · **Status:** approved, ready for an implementation plan

## Goals

1. **Don't re-download every time** — cache fetched JSON, keyed by a server-declared version.
2. **Fast re-render** — don't re-decode/re-validate a screen the client already parsed this session.
3. **Secure at rest** — a cache on a jailbroken device is the spec's layer-4 attacker; re-verify on load, protect the files, allow encryption.

## Decisions

- **Freshness = version manifest.** A small signed index (`screenKey → version`) tells the client what changed; re-fetch only those screens.
- **At-rest security = integrity by default, encryption opt-in.** Re-verify the signature on every disk load (mandatory) + iOS Data Protection; app-level AES-GCM is an opt-in strategy for sensitive payloads.
- **Render cache is in-memory only.** Decoded trees do not persist across launches (the disk cache does); a relaunch pays one decode per screen. Accepted.
- **One manifest for all screens** (per-namespace manifests deferred until screen counts demand it).

## Architecture — three tiers

| Tier | Solves | Where | Lifetime |
| --- | --- | --- | --- |
| **Manifest** (`screenKey → version`, signed) | knowing *what* to re-download | memory + disk | refreshed on demand |
| **Payload disk cache** (signed envelope bytes, keyed `screenKey@version`) | not re-downloading; offline last-good | disk, Data-Protected (+ opt-in AES-GCM) | until evicted |
| **Decoded render cache** (validated `MurtiNode` tree, keyed `screenKey@version`) | not re-decoding/re-validating | memory, bounded LRU | session / memory pressure |

Both caches are keyed by `screenKey@version` → **a new version is a new key**. Entries are immutable; old versions are evicted, never mutated. No invalidation races.

The `DataContext` (nav params, API responses, tokens) is **not** cached — it stays live per screen instance, so a cached tree never bakes in stale data.

## Ports (Strategy — swappable, testable, DI; same style as network/crypto)

```swift
public protocol MurtiCacheStore: Sendable {        // persistent bytes; default FileCacheStore
    func data(for key: String) async -> Data?
    func store(_ data: Data, for key: String) async
    func remove(_ key: String) async
}

public protocol MurtiCacheCipher: Sendable {       // opt-in at-rest encryption; default PassthroughCipher
    func seal(_ plaintext: Data) throws -> Data
    func open(_ ciphertext: Data) throws -> Data
}
```

- `FileCacheStore` — writes to Caches/Application Support with `.completeUntilFirstUserAuthentication`; filename = `hex(SHA256(key))` (CryptoKit) so arbitrary version strings are filesystem-safe.
- `PassthroughCipher` — no-op default.
- `AESGCMCipher(keyRef:)` — opt-in; symmetric key held in the Keychain (optionally Secure-Enclave-wrapped).

## Mutable state — the coordinator

`MurtiEngine` is a `@MainActor` value type; the render cache, manifest map, and last-seen manifest sequence are mutable session state. Hold them in a reference `MurtiCacheCoordinator` (an actor, or `@MainActor final class`) that the engine references, so the engine keeps value semantics while the coordinator owns mutation and eviction.

```swift
public struct MurtiCache: Sendable {
    let store: any MurtiCacheStore
    let cipher: any MurtiCacheCipher
    var renderCacheLimit: Int = 32           // decoded trees held in memory
    var diskByteLimit: Int = 8 * 1024 * 1024 // soft cap, LRU-evicted
}
```

## `load()` flow (cache slots in front of fetch)

`load(.key("dashboard"))`:

1. `version = manifest["dashboard"]` (or last-known if the manifest hasn't been refreshed).
2. **Render-cache hit** for `dashboard@version` → return the decoded tree. No fetch, no decode, no re-verify (verified this session). *→ fast re-render.*
3. else **disk hit** → read bytes → `cipher.open` → **re-verify signature** → decode → validate → fill render cache → return. *→ no download, survives relaunch.*
4. else **miss/stale** → network adapter fetch → verify → decode → validate → `cipher.seal` → **store the signed envelope** → fill render cache → return. *→ first fetch.*
5. **network failure at step 4** → serve last-good disk entry (re-verified) → bundled default → `.failed`. *→ fail-closed.*

We cache the **signed envelope** (not the plaintext tree) so the signature travels with it and step 3 can re-verify.

## Manifest flow

- `engine.refreshManifest()` — adopter-triggered (launch / foreground / pull-to-refresh). Fetch → **verify signature** → check `sequence` is **≥ last seen** (reject downgrades) → update the in-memory map and persist (Data-Protected) for offline launch.
- `engine.prefetch([screenKey])` — optional warming: fetch+cache without rendering.
- Murti owns no timers or lifecycle — the adopter decides cadence.

```swift
struct Manifest: Codable, Sendable {
    let sequence: Int              // monotonic; reject an older one (rollback defense)
    let screens: [String: String] // screenKey -> version
}
```

## Security specifics

- **Re-verify on every disk load** (mandatory). Fail → evict the entry, treat as a miss. A tampered cache can never render.
- **Signed manifest + no-downgrade.** The manifest is a payload; verify it, and reject a `sequence` lower than the last seen — blocks pinning the client to a known-bad screen version.
- **Data Protection** on all cache files; **opt-in AES-GCM** on top for confidentiality.
- **Bounds re-checked** on every cache load (cheap) — caps can tighten between releases.
- Verification reuses the engine's existing `PayloadSecurity` / `MurtiSignatureVerifier`; cache adds no new trust root.

## API surface (opt-in, additive — nil cache = today's behavior)

```swift
let engine = MurtiEngine(
    componentFactory: .withBuiltins,
    screenFactory: screens,
    actionDispatcher: MurtiActionDispatcher(network: client, navigator: nav),
    security: .signed(verifier),
    cache: MurtiCache(store: FileCacheStore(), cipher: PassthroughCipher())
)
```

## Eviction

- **Render cache:** bounded count (`renderCacheLimit`, default 32), LRU; purged on memory-pressure notification.
- **Disk cache:** soft byte cap (`diskByteLimit`), LRU by last-access; a screen's superseded versions become eligible for eviction when the manifest advances its version.

## Testing (deterministic, no network)

- hit / miss / stale by version; new version = new key.
- disk tamper → re-verify fails → evict → miss.
- forged manifest (bad signature) and older manifest (`sequence` downgrade) → rejected.
- offline (throwing network) → serves re-verified last-good; then bundled default; then `.failed`.
- cipher round-trip: `PassthroughCipher` and a fake AES cipher.
- render cache skips a second decode — inject a counting decoder / hook and assert one decode across two loads of the same version.

## Alternatives considered (rejected)

- **Adapter-level URLCache / ETag** — you chose manifest freshness, and HTTP caching wouldn't re-verify signatures or give a Murti-managed secure at-rest cache.
- **Disk-only cache (no in-memory tier)** — simpler, but re-decodes/re-validates on every navigation, losing the render win.

## Deferred

- Persisting decoded trees across launches.
- Per-namespace manifests for very large catalogs.
- Hybrid-encryption-at-rest sharing keys with the (future) transport hybrid encryption.
