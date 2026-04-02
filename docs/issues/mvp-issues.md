# BrickCanvas MVP Issue Backlog

This file contains a structured set of implementation-ready issues for the BrickCanvas MVP.

Suggested labels:

- `epic`
- `feature`
- `tech`
- `ux`
- `algorithm`
- `export`
- `infra`
- `good first task`
- `mvp`
- `v1`

Suggested priority scale:

- `P0` = blocks MVP
- `P1` = important for MVP quality
- `P2` = can happen after first usable version

Suggested effort scale:

- `S` = small
- `M` = medium
- `L` = large

---

## Epic 1 — Foundations

### Issue 1 — Set up iOS app skeleton
**Labels:** `epic`, `feature`, `mvp`, `P0`
**Effort:** M

#### Goal
Create the initial iOS application skeleton for BrickCanvas using SwiftUI and a structure suitable for a solo developer.

#### Scope
- Create the app target
- Set up basic navigation
- Add placeholder screens
- Establish folder/module structure
- Add app branding placeholders

#### Acceptance Criteria
- App launches successfully
- Root navigation is in place
- Placeholder screens exist for:
  - Home
  - New Project
  - Project Detail
  - Settings
- Project structure is clean and documented

#### Notes
Prefer a pragmatic architecture, not overengineered.

---

### Issue 2 — Define project domain models
**Labels:** `tech`, `mvp`, `P0`
**Effort:** M

#### Goal
Define the core data models used throughout the app.

#### Scope
Create initial models for:
- Project
- SourceImage
- MosaicGrid
- MosaicCell
- LegoColor
- PartRequirement
- ExportOptions

#### Acceptance Criteria
- Models compile cleanly
- Models are decoupled from the UI layer
- Core types are documented with comments
- Example test data can be created

#### Notes
These models should support local persistence later.

---

### Issue 3 — Establish app module boundaries
**Labels:** `tech`, `mvp`, `P1`
**Effort:** S

#### Goal
Document and create the initial internal module/service boundaries.

#### Scope
Define responsibilities for:
- ImageImport
- ImagePreprocessing
- Palette
- ColorMatcher
- MosaicGenerator
- PartPlanner
- ExportEngine
- ProjectStorage

#### Acceptance Criteria
- A short architecture note exists in the repo
- Responsibilities are clear
- No obvious circular dependencies in the initial design

---

## Epic 2 — Image Import and Editing

### Issue 4 — Import photo from library
**Labels:** `feature`, `ux`, `mvp`, `P0`
**Effort:** M

#### Goal
Let users select an image from the photo library.

#### Scope
- Add photo picker integration
- Support common image formats
- Normalize orientation after import

#### Acceptance Criteria
- User can select a photo
- Selected image is displayed in the app
- Rotated photos are handled correctly
- Failure states are handled gracefully

---

### Issue 5 — Capture photo with camera
**Labels:** `feature`, `ux`, `mvp`, `P1`
**Effort:** M

#### Goal
Let users capture a new image with the device camera.

#### Acceptance Criteria
- User can open camera flow
- Captured image becomes the project source image
- Permission handling works properly

#### Notes
Can be deferred until after photo library import if needed.

---

### Issue 6 — Build crop and framing UI
**Labels:** `feature`, `ux`, `mvp`, `P0`
**Effort:** L

#### Goal
Allow users to crop and frame the source image before mosaic generation.

#### Scope
- Crop rectangle interaction
- Preset aspect ratios
- Pan and zoom
- Live preview

#### Acceptance Criteria
- User can crop image reliably
- Crop result is stable and repeatable
- At least one square-focused mode exists for LEGO art use cases

---

### Issue 7 — Add image adjustment presets
**Labels:** `feature`, `ux`, `P2`
**Effort:** M

#### Goal
Provide simple image adjustments that improve mosaic results.

#### Scope
- Contrast preset
- Brightness preset
- Saturation preset
- Optional portrait preset

#### Acceptance Criteria
- Presets can be applied and previewed
- Resulting image can be passed into the mosaic pipeline

---

## Epic 3 — Mosaic Configuration

### Issue 8 — Add mosaic size selection
**Labels:** `feature`, `ux`, `mvp`, `P0`
**Effort:** S

#### Goal
Let users choose output mosaic size.

#### Scope
Support initial preset sizes such as:
- 24x24
- 48x48
- 64x64

#### Acceptance Criteria
- Size can be selected before generation
- Selected size affects output resolution correctly
- UI clearly communicates stud dimensions

---

### Issue 9 — Add style presets for conversion
**Labels:** `feature`, `ux`, `P1`
**Effort:** M

#### Goal
Offer user-friendly conversion presets.

#### Example presets
- Balanced
- High Contrast
- Portrait
- Bold Colors

#### Acceptance Criteria
- Presets are visible and selectable
- Presets map to deterministic conversion parameters

---

### Issue 10 — Add allowed color set selection
**Labels:** `feature`, `algorithm`, `P1`
**Effort:** M

#### Goal
Allow users to restrict conversion to a chosen set of LEGO colors.

#### Scope
- Full palette mode
- Reduced palette mode
- Future-friendly design for custom owned colors

#### Acceptance Criteria
- User can choose a palette mode
- Color matcher respects selected palette

---

## Epic 4 — Color and Palette System

### Issue 11 — Define initial LEGO color palette dataset
**Labels:** `algorithm`, `tech`, `mvp`, `P0`
**Effort:** M

#### Goal
Create the initial palette of LEGO-compatible colors for the MVP.

#### Scope
For each color, store:
- display name
- internal id
- RGB value
- optional notes

#### Acceptance Criteria
- Palette is available in code
- Palette can be iterated and displayed
- Palette is documented

#### Notes
Start curated and small. Expand later.

---

### Issue 12 — Implement perceptual color distance utility
**Labels:** `algorithm`, `mvp`, `P0`
**Effort:** M

#### Goal
Implement a perceptual color matching approach better than naive RGB distance.

#### Acceptance Criteria
- Utility can compare two colors and return a distance
- Matching behaves better than plain Euclidean RGB for test cases
- Logic is unit tested

---

### Issue 13 — Implement pixel-to-LEGO color matcher
**Labels:** `algorithm`, `mvp`, `P0`
**Effort:** M

#### Goal
Map arbitrary image pixels to the nearest available LEGO color.

#### Acceptance Criteria
- Any input pixel can be mapped to a palette color
- Matching respects allowed palette restrictions
- Deterministic results for the same input
- Unit tests cover representative cases

---

### Issue 14 — Add optional pre-quantization / palette reduction stage
**Labels:** `algorithm`, `P2`
**Effort:** M

#### Goal
Improve final mosaic quality by optionally reducing the image palette before final color mapping.

#### Acceptance Criteria
- Optional pre-processing stage exists
- Results can be compared against direct mapping

---

## Epic 5 — Mosaic Generation

### Issue 15 — Downsample crop to stud-aligned working raster
**Labels:** `algorithm`, `mvp`, `P0`
**Effort:** M

#### Goal
Convert the cropped source image directly from original resolution into a stud-aligned working raster that preserves as much perceptual image information as possible for later palette quantization and dithering.

#### Acceptance Criteria
- 24x24 selection generates a deterministic 24x24 working raster
- 48x48 selection generates a deterministic 48x48 working raster
- 64x64 selection generates a deterministic 64x64 working raster
- The working raster is derived directly from the cropped original image, not from a previously quantized intermediate image
- Downsampling uses a documented, testable resampling strategy appropriate for strong reduction ratios
- Resulting samples remain in a full-color working representation and are not yet mapped to LEGO palette colors
- Downsampling is stable and covered by tests

---

### Issue 16 — Quantize working raster and generate mosaic grid
**Labels:** `algorithm`, `mvp`, `P0`
**Effort:** M

#### Goal
Convert the stud-aligned working raster into the final `MosaicGrid` by mapping every cell to an allowed LEGO color using a high-quality, efficient dithering algorithm.

#### Acceptance Criteria
- Grid dimensions match selected size
- Every cell has coordinates and a resolved target color
- Palette quantization is performed against the allowed LEGO palette, not against unrestricted RGB output
- Dithering is implemented as error diffusion on the stud raster
- The default algorithm is documented and chosen for a quality/performance tradeoff suitable for interactive use
- The implementation uses a modern standard baseline:
  Ostromoukhov-style variable-coefficient error diffusion as the default base, with Zhou/Fang-style threshold modulation evaluated as an optional follow-up if it materially improves mid-tone quality without destabilizing color output
- The pipeline remains deterministic and testable
- Grid can be rendered in previews and used by downstream systems

---

### Issue 17 — Render interactive mosaic preview
**Labels:** `feature`, `ux`, `mvp`, `P0`
**Effort:** L

#### Goal
Display the generated mosaic as a zoomable preview inside the app.

#### Scope
- Render colored stud cells
- Support zoom and pan
- Show crisp grid behavior where useful

#### Acceptance Criteria
- User can inspect the generated mosaic visually
- Preview updates when settings change
- Performance is acceptable for target MVP sizes

---

### Issue 18 — Add coordinate system to mosaic grid
**Labels:** `feature`, `ux`, `export`, `P1`
**Effort:** M

#### Goal
Add human-readable coordinates for use in instructions and exports.

#### Acceptance Criteria
- Rows and columns can be labeled consistently
- Coordinate labels can be toggled in preview/export contexts

---

## Epic 6 — Parts Planning

### Issue 19 — Create 1x1 part requirement generator
**Labels:** `algorithm`, `mvp`, `P0`
**Effort:** M

#### Goal
Generate a parts list assuming each stud maps to one 1x1 element.

#### Acceptance Criteria
- Parts list totals equal total stud count
- Requirements are grouped by color
- Output is deterministic

---

### Issue 20 — Add part requirement summary UI
**Labels:** `feature`, `ux`, `mvp`, `P0`
**Effort:** M

#### Goal
Display the generated parts list in a clean and usable way.

#### Scope
- Color name
- quantity
- visual swatch
- total pieces

#### Acceptance Criteria
- Parts list is easy to read
- Totals are correct
- Empty/error states are handled

---

### Issue 21 — Add estimated cost placeholder model
**Labels:** `tech`, `P2`
**Effort:** S

#### Goal
Prepare the data model for future cost estimation without implementing real pricing yet.

#### Acceptance Criteria
- Cost estimate field exists in domain model or export model
- UI can show placeholder or unavailable state gracefully

---

## Epic 7 — Build Instructions and Export

### Issue 22 — Generate simple grid-based build plan
**Labels:** `feature`, `export`, `mvp`, `P0`
**Effort:** M

#### Goal
Produce a first practical build plan from the mosaic grid.

#### Scope
- Full grid output
- Coordinates
- Color legend

#### Acceptance Criteria
- User can understand how to place studs based on the plan
- Plan matches preview and parts list

---

### Issue 23 — Add quadrant-based instruction view for larger mosaics
**Labels:** `feature`, `export`, `P1`
**Effort:** M

#### Goal
Make larger mosaics easier to build by splitting them into sections.

#### Acceptance Criteria
- 48x48 and larger mosaics can be divided into logical sub-sections
- UI/export remains readable

---

### Issue 24 — Export build plan as image
**Labels:** `export`, `mvp`, `P0`
**Effort:** M

#### Goal
Allow users to export the mosaic plan as an image.

#### Acceptance Criteria
- User can save or share an image export
- Export contains enough detail to build from

---

### Issue 25 — Export parts list as CSV
**Labels:** `export`, `P1`
**Effort:** S

#### Goal
Allow exporting the parts list as CSV for later processing.

#### Acceptance Criteria
- CSV contains stable column headers
- CSV data matches in-app parts list

---

### Issue 26 — Export build plan as PDF
**Labels:** `export`, `P1`
**Effort:** M

#### Goal
Provide a printable PDF build plan.

#### Acceptance Criteria
- PDF export succeeds for supported mosaic sizes
- PDF includes at minimum:
  - title
  - preview
  - parts list
  - build grid

---

## Epic 8 — Persistence and Project Management

### Issue 27 — Save projects locally
**Labels:** `feature`, `tech`, `mvp`, `P0`
**Effort:** M

#### Goal
Allow users to save generated projects on device.

#### Acceptance Criteria
- Saved projects can be reopened
- Core project data persists correctly
- Corrupt or missing data is handled safely

---

### Issue 28 — Build project list screen
**Labels:** `feature`, `ux`, `mvp`, `P0`
**Effort:** M

#### Goal
Provide a project overview screen for saved mosaics.

#### Acceptance Criteria
- User can see saved projects
- User can open a saved project
- Basic metadata is visible

---

### Issue 29 — Add delete and rename project actions
**Labels:** `feature`, `ux`, `P1`
**Effort:** S

#### Goal
Support simple project management operations.

#### Acceptance Criteria
- User can rename a project
- User can delete a project with confirmation

---

## Epic 9 — Quality, Performance, and Testing

### Issue 30 — Add unit tests for color matching
**Labels:** `tech`, `algorithm`, `mvp`, `P0`
**Effort:** M

#### Goal
Cover the core color matching logic with tests.

#### Acceptance Criteria
- Tests cover representative palette mapping cases
- Tests are deterministic and fast

---

### Issue 31 — Add unit tests for parts counting
**Labels:** `tech`, `algorithm`, `mvp`, `P0`
**Effort:** S

#### Goal
Verify that generated parts totals are always correct.

#### Acceptance Criteria
- Tests cover multiple grid configurations
- Totals match expected stud counts

---

### Issue 32 — Benchmark preview performance for target grid sizes
**Labels:** `tech`, `ux`, `P1`
**Effort:** M

#### Goal
Check that mosaic previews remain smooth enough for common sizes.

#### Acceptance Criteria
- Basic benchmark notes exist
- Performance problems are identified and documented

---

### Issue 33 — Add snapshot or visual regression checks for preview rendering
**Labels:** `tech`, `ux`, `P2`
**Effort:** M

#### Goal
Protect the visual rendering pipeline against accidental regressions.

#### Acceptance Criteria
- At least one stable visual check exists for preview rendering

---

## Epic 10 — Repo Hygiene and Delivery

### Issue 34 — Add CONTRIBUTING and development notes
**Labels:** `infra`, `P2`
**Effort:** S

#### Goal
Document how the project is structured and how to work on it.

#### Acceptance Criteria
- Basic development notes exist
- Build/run instructions are documented

---

### Issue 35 — Add issue templates for feature and bug reports
**Labels:** `infra`, `P1`
**Effort:** S

#### Goal
Prepare the repository for structured planning and feedback.

#### Acceptance Criteria
- Feature request template exists
- Bug report template exists

---

### Issue 36 — Add GitHub labels and milestone plan documentation
**Labels:** `infra`, `P1`
**Effort:** S

#### Goal
Document the intended labels and milestones used for managing the backlog.

#### Acceptance Criteria
- Label list is documented
- MVP milestone grouping is documented

---

# Recommended MVP Cut Line

If you want the smallest strong first version, treat these as the MVP cut line:

- Issue 1
- Issue 2
- Issue 4
- Issue 6
- Issue 8
- Issue 11
- Issue 12
- Issue 13
- Issue 15
- Issue 16
- Issue 17
- Issue 19
- Issue 20
- Issue 22
- Issue 24
- Issue 27
- Issue 28
- Issue 30
- Issue 31

# Recommended First Build Order

1. Issue 1 — Set up iOS app skeleton
2. Issue 2 — Define project domain models
3. Issue 11 — Define initial LEGO color palette dataset
4. Issue 12 — Implement perceptual color distance utility
5. Issue 13 — Implement pixel-to-LEGO color matcher
6. Issue 4 — Import photo from library
7. Issue 6 — Build crop and framing UI
8. Issue 8 — Add mosaic size selection
9. Issue 15 — Resize image to stud resolution
10. Issue 16 — Generate mosaic grid model
11. Issue 17 — Render interactive mosaic preview
12. Issue 19 — Create 1x1 part requirement generator
13. Issue 20 — Add part requirement summary UI
14. Issue 22 — Generate simple grid-based build plan
15. Issue 24 — Export build plan as image
16. Issue 27 — Save projects locally
17. Issue 28 — Build project list screen
18. Issue 30 — Add unit tests for color matching
19. Issue 31 — Add unit tests for parts counting
