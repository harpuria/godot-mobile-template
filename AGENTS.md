# Repository instructions

## Start here

- At the start of a new task, read [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for entry points, ownership, task-to-file mappings and validation routes. Follow its task-specific document links before editing the relevant area.
- For live Godot editor work, use the Godot MCP selected by the user or the receiving project. The template default is Godot AI. See [connection and replacement](docs/DEVELOPMENT.md#godot-mcp).
- When applying this template to a new or existing game, or updating a derived game to a newer template version, follow [docs/template/APPLYING.md](docs/template/APPLYING.md).

## Commands

- Run commands from the repository root. Validation commands are listed in [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md#변경-후-검증).
- If `godot` is not on PATH, use the Godot 4.7.2 executable path instead (macOS default: `/Applications/Godot.app/Contents/MacOS/Godot`).

## Boundaries

- Game-specific code belongs under `game/`.
- `examples/` holds reference implementations (e.g. purchase ledger). Copy them into `game/` and adapt; game code must not load files from `examples/`.
- `native/` holds template-owned native plugin sources. Build outputs go to `addons/` and stay out of Git until device-verified.
- Store submission steps live in `docs/STORE_RELEASE.md`. Keep one store per Android export preset; never ship Google Play Billing in a ONE store build.
- Do not access mobile plugins directly from game code.
- Use AdsService (`App.ads`) for advertisements.
- Use BillingService (`App.billing`) for IAP.
- Use SaveManager for persistence; use Settings for user preferences.
- Use AudioManager for audio and SceneManager for scene transitions.
- Do not modify `core/` or `services/` unless framework changes are required.
- Prefer existing abstractions over creating new managers.
- Avoid duplicate singleton managers. App owns service instances.
- Read `docs/ARCHITECTURE.md` before changing initialization, persistence, service contracts or adapters.

## Dependencies and validation

- Godot is locked to 4.7.2. Never silently upgrade dependency versions.
- Do not introduce new dependencies without documenting them.
- Any new plugin or library must be added to the README dependency BOM and `docs/DEPENDENCIES.md` with exact version, source, license, native SDKs and compatibility evidence.
- Unverified native plugins remain deferred; use interface/Mock until their compatibility is established.
- Mock purchases must never succeed in release builds.
- For native changes, read `docs/DEPENDENCIES.md` and perform Android/iOS export and device checks before claiming Verified.
- Run the affected integration scenarios in `tests/integration.tscn`; `--disabled` and `--native` cover unavailable initialization paths.
- Record actual validation and remaining limits of template features in `docs/template/VALIDATION.md`; a derived game records its own validation in its game documents. Do not claim device verification from Desktop tests.
- Keep production IDs, signing material and secrets outside Git.

## Code and documentation

- Use GDScript, simple explicit APIs and typed public boundaries.
- Add a short Korean `##` class description at the top of each `.gd` file and Korean doc comments for major methods.
- Keep game rules and data schemas in `game/`; register save schema and migrations through the `app/init_script` hook instead of editing `scenes/bootstrap.gd`. Adapters must not grant game-specific rewards.
- Keep generated design/plan/validation documents under `docs/` and update README entry points when behavior changes. `docs/template/` holds template history and procedures; do not use it for game plans or design.
- When changing the template version, update `GameConfig.TEMPLATE_VERSION`, README and `docs/template/CHANGELOG.md` together.
- Update `docs/CODEBASE_MAP.md` in the same change when moving files or changing entry flows, public access APIs, configuration propagation or validation commands.
