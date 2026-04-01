# BrickCanvas

Turn photos into LEGO-style mosaic art with build plans and parts lists.

## Vision

BrickCanvas is a mobile-first app that lets people upload or capture a photo and transform it into a custom brick mosaic that can actually be built.

The app should bridge the gap between a beautiful visual preview and a practical building plan by generating:

- a brick mosaic preview
- a reduced color version mapped to real LEGO colors
- a build plan / instruction layout
- a parts list with quantities by part and color
- optional sourcing support via third-party services

## Problem

People often want to recreate photos, portraits, pets, family moments, or artwork as LEGO wall art, but doing so manually is tedious.

Current workflows are fragmented:

- image editing in one tool
- palette reduction in another
- manual counting of parts
- no clean mobile-first experience

BrickCanvas should make the full flow easy, visual, and fun.

## Core User Flow

1. User imports a photo from the camera or photo library
2. User crops and adjusts the image
3. User chooses a mosaic size and style
4. App maps the image to a LEGO-compatible color palette
5. App generates a stud-based mosaic preview
6. App shows:
   - final preview
   - build instructions
   - parts list
   - optional price estimate
7. User exports or saves the project

## Target Users

- LEGO fans
- families
- hobby builders
- parents doing creative projects with children
- people who want personalized wall art
- users who want custom alternatives to official LEGO Art sets

## MVP

The first version should focus on the shortest useful path from photo to buildable mosaic.

### MVP Features

- import image from photo library or camera
- crop image to target aspect ratio
- choose mosaic size, for example:
  - 24x24
  - 48x48
  - 64x64
- reduce the image to a real LEGO color palette
- render a stud grid preview
- generate a parts list by color and quantity
- export a simple build plan

### MVP Constraints

To keep scope realistic, the MVP should initially use only simple piece strategies such as:

- 1x1 round plates
- or 1x1 square plates / tiles

This avoids early complexity around advanced piece optimization and availability.

## Future Features

- support larger parts like 2x2 and 2x4 for optimization
- inventory-aware mode using parts the user already owns
- build using pieces from selected sets only
- face-aware portrait enhancement
- background removal
- automatic contrast and edge enhancement
- official LEGO Art frame presets
- multi-panel murals
- Rebrickable or BrickLink export
- PDF build instructions
- project sync and sharing

## Product Differentiators

BrickCanvas can stand out through:

- mobile-first UX
- family-friendly flow
- practical buildability, not just visual conversion
- support for real LEGO colors and real piece constraints
- optional optimization based on owned inventory

## Technical Overview

### Image Pipeline

The processing flow should roughly be:

1. load image
2. normalize orientation
3. crop to target ratio
4. resize to target stud resolution
5. optionally improve contrast / clarity
6. quantize colors to a LEGO palette
7. generate the mosaic grid
8. count parts and produce build output

### Color Mapping

One of the key quality factors is color mapping.

The app should map image colors to a restricted palette of real LEGO colors using perceptual matching rather than simple RGB distance.

Possible approach:

- maintain a curated LEGO palette
- convert colors into a perceptual space
- pick nearest allowed color
- optionally apply palette reduction before final mapping

### Mosaic Grid

The processed image becomes a 2D stud grid.

Example:

- 48x48 mosaic
- 2304 stud positions
- each cell stores:
  - x coordinate
  - y coordinate
  - target color
  - optional assigned part

### Part Planning

MVP:

- one stud = one part
- count by color

Later:

- detect larger monochrome regions
- replace many 1x1 parts with larger elements where useful
- optimize against cost, availability, and build simplicity

### Build Plan Generation

Initial output formats can be simple:

- full coordinate grid
- row-by-row build layout
- quadrant-based sections for larger mosaics

Later versions can add more polished step-by-step instruction generation.

### Export

Possible export targets:

- image export
- PDF instructions
- plain text parts list
- CSV parts list
- future sourcing export

## External Data

Useful external data sources include:

- LEGO color definitions
- available parts by color
- metadata for parts and sets
- optional pricing and inventory data

Rebrickable is an obvious starting point for:

- colors
- parts
- sets
- inventory metadata

## Suggested App Architecture

For a first version, an Apple-platform-first native app makes sense.

### Suggested stack

- SwiftUI for UI
- Swift concurrency for processing pipeline orchestration
- Core Image / Vision / Accelerate where useful
- local persistence for saved projects
- optional networking for external metadata

### Suggested modules

- `ImageImport`
- `ImagePreprocessing`
- `Palette`
- `ColorMatcher`
- `MosaicGrid`
- `PartPlanner`
- `InstructionGenerator`
- `ExportEngine`
- `ProjectStorage`

## Current App Scaffold

The repository now contains the initial iOS app skeleton for the MVP:

- SwiftUI app entry point
- tab-based root navigation
- placeholder screens for Home, New Project, Projects, and Settings
- XcodeGen-based project definition in `project.yml`

This scaffold is intentionally limited to app structure and navigation. Domain models, image processing, and color matching are introduced in later PR slices.

## Local Development

Generate the Xcode project:

```bash
xcodegen generate
```

Build from the command line:

```bash
xcodebuild -project BrickCanvas.xcodeproj -scheme BrickCanvas -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' build
```

## Current Palette Dataset

The current MVP palette dataset lives in `BrickCanvas/Resources/Palette/mvp-palettes-v1.json`.

- versioned JSON resource
- one curated palette: `mvp-default`
- small starter set intended for MVP reviewability and future expansion

The dataset is loaded through `BundledPaletteService` and validated for duplicate IDs and structurally invalid entries before use.

## Key Challenges

### Visual quality

Bad color reduction will immediately make the result look disappointing.

### Portrait handling

Faces are highly sensitive and often need tuned contrast and palette behavior.

### Buildability

A pretty mosaic is not automatically easy or cheap to build.

### Real-world constraints

Not every part exists in every color, so piece planning must eventually respect actual availability.

### UX

The app should feel creative and accessible, not like a complex CAD tool.

## Monetization Ideas

- free small mosaics, paid larger exports
- one-time Pro unlock
- premium export features
- subscription for unlimited projects and advanced optimization
- optional affiliate revenue from sourcing links

## Milestones

### Milestone 1 — Image to Mosaic

- import image
- crop and resize
- palette mapping
- mosaic preview

### Milestone 2 — Build Output

- parts counting
- grid plan output
- export support

### Milestone 3 — Quality Improvements

- portrait presets
- contrast presets
- better palette tuning

### Milestone 4 — Advanced Planning

- larger part optimization
- owned inventory mode
- external integration

## Open Questions

- Should the app target official LEGO Art dimensions first?
- Should the MVP use only 1x1 parts?
- Should PDF export be included in the first release?
- Should sourcing integrations be delayed until after the core generation flow is polished?

## Working Taglines

- Build your memories in bricks
- Turn photos into brick art
- Your photo, rebuilt in LEGO style
- From snapshot to brick masterpiece

## Immediate Next Step

Build a technical prototype for:

1. downscaling an image to stud resolution
2. mapping pixels to a LEGO color palette
3. rendering a mosaic preview
4. generating a simple color-based parts list
