# Project Agent Guide

## Project overview
Sweph is a cross-platform bindings library of Swiss Ephemeris APIs for Dart and Flutter. It provides 100% API coverage, using FFI for native platforms and Wasm (via Emscripten and wasm_ffi) for Web platforms.

## Repository map
- `lib/` — Dart library code and API bindings
- `native/` — C source code of the original Swiss Ephemeris and utilities
- `assets/` — bundled ephemeris files and precompiled Wasm
- `example/` — Flutter example application testing the plugin
- `tool/` — helper scripts for version bumping

## Working commands
- Setup: `flutter pub get`
- Build Wasm: `make wasm` (requires Docker to run Emscripten)
- Lint: `flutter analyze`
- Test: `make test` (runs the Flutter example)
- Publish check: `make publish`

## Engineering constraints
- Follow KISS and YAGNI; prefer the smallest change that satisfies the request.
- Preserve existing public behavior unless the task explicitly changes it.
- Updates to the C codebase or Wasm build process must be compiled using `make wasm` which requires Docker.
- The repository follows a versioning scheme tied to the Swiss Ephemeris version, with an automated script at `tool/bump_version.dart`.

## Context discipline
- Start with targeted search and the repository map.
- Read only files relevant to the task and follow linked documentation as needed.
- Do not load generated, vendored, dependency, or build-output directories unless required.

## Documentation routing
- User setup and usage: [`README.md`](README.md)
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)

## Definition of done
- Relevant tests, lint, type checks, and builds pass.
- New behavior includes appropriate tests when practical.
- No unrelated files or dependencies were changed.
- Only documentation made inaccurate by the change was updated.

## Documentation maintenance
- Update `AGENTS.md` only when agent workflow, commands, navigation, or constraints change.
- Update `README.md` only when user-facing setup, configuration, usage, or capabilities change.
