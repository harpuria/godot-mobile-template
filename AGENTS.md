# Repository instructions

## Start here

- At the start of a new task, read [docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md) for entry points, ownership, task-to-file mappings and validation routes. Follow its task-specific document links before editing the relevant area.
- When applying this template to a new or existing game, or updating a derived game to a newer template version, follow [docs/template/APPLYING.md](docs/template/APPLYING.md).

## Commands

- Shell commands must be prefixed with `rtk`; use `rtk proxy <command>` for unfiltered output.
- In command chains, prefix every segment. Raw commands are allowed only for debugging.

## Boundaries

- Game-specific code belongs under `game/`.
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
