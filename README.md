# BrickCanvas

BrickCanvas is an iOS SwiftUI prototype for turning photos into brick-style mosaic projects with a generated preview, parts summary, and build-plan output.

## Status

BrickCanvas is currently on hold.

Development is paused until there is a new product vision. The prototype proved useful for validating the pipeline, but the current approach did not reach the required quality level for a real product.

### Why the project is on hold

- sourcing the required parts is too difficult
- sourcing suitable baseplates is too difficult
- image quality at smaller mosaic sizes is not good enough
- image quality with standard LEGO colors is not good enough

### Possible future directions

These are ideas only and are not planned work:

- use 3D-printed parts
- use a non-LEGO production method

## Current Implementation

The repository contains a working prototype, not just an app shell.

### Implemented today

- SwiftUI app with tab-based navigation
- photo import from the iOS photo library
- image normalization during import
- interactive crop editor with multiple aspect presets
- square mosaic sizing from 16x16 up to 128x128
- mosaic preview generation with configurable dithering
- bundled palette loading and color activation controls
- generated project assembly from imported image, crop, palette, and grid
- parts list generation for the selected mosaic
- build-plan generation and rasterized build-plan preview
- PNG sharing for the generated build plan
- unit tests for domain models and core services

### Current app surfaces

- `Home`: placeholder screen only
- `New Project`: implemented prototype flow for import, crop, preview, and project generation
- `Projects`: currently shows a generated project detail screen rather than a persisted project list
- `Settings`: implemented controls for dithering and palette activation

### Not implemented

- real project persistence behind `ProjectStorage`
- a finished home dashboard
- a real projects overview backed by saved data
- sourcing integrations for parts or baseplates
- cost estimation
- inventory-aware planning
- larger-part optimization
- PDF export
- production-ready image quality for small outputs

## Technical Snapshot

BrickCanvas is currently an Apple-platform-first prototype with these building blocks:

- SwiftUI for all current UI
- Swift Concurrency in the generation flow
- XcodeGen via `project.yml`
- `DitheringEngine` as an external Swift Package
- domain models for projects, grids, colors, parts, and build-plan artifacts
- service-based architecture for import, palette loading, color matching, mosaic generation, part planning, build-plan generation, and export

Relevant architecture documents:

- [ADR 0001: SwiftUI First](docs/adr/0001-swiftui-first.md)
- [Architecture Guidelines](docs/architecture.md)

## Repository Structure

- `BrickCanvas/App`: app entry point and tab wiring
- `BrickCanvas/Features`: SwiftUI feature screens
- `BrickCanvas/Domain`: domain models and fixtures
- `BrickCanvas/Services`: service contracts and implementations
- `BrickCanvas/Storage`: storage contracts
- `BrickCanvas/Resources`: bundled palette and fixture data
- `BrickCanvasTests`: unit tests for domain and service behavior

## Local Development

### Requirements

- Xcode 26.4
- XcodeGen
- Metal Toolchain

BrickCanvas depends on [`DitheringEngine`](https://github.com/Eskils/DitheringEngine), which includes Metal shader code. The local Metal Toolchain must therefore be available for complete builds.

Check whether the Metal Toolchain is installed:

```bash
xcodebuild -showComponent MetalToolchain
```

Install it if needed:

```bash
xcodebuild -downloadComponent MetalToolchain
```

Generate the Xcode project:

```bash
./scripts/generate-xcode-project.sh
```

`project.yml` is the only source of truth for the generated Xcode project. `BrickCanvas.xcodeproj/` is not versioned and should be regenerated locally when needed.

Build from the command line:

```bash
xcodebuild -project BrickCanvas.xcodeproj -scheme BrickCanvas -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' build
```

Run tests from the command line:

```bash
xcodebuild test -project BrickCanvas.xcodeproj -scheme BrickCanvas -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'
```

## Test Coverage Focus

The current automated tests primarily cover:

- domain model invariants
- image import and crop services
- perceptual color distance and color matching
- mosaic generation
- part planning
- build-plan generation
- export engine behavior
- generated project assembly

## Notes

The README now reflects the current prototype state rather than the original product ambition. If work resumes, the next documentation update should be driven by the new product direction instead of the earlier LEGO-mosaic roadmap.
