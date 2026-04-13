# Project Documentation: Precision Atelier UI Refinement

## Precision Atelier Header System
The application now uses a centralized header system located in `lib/core/widgets/atelier_header.dart`. This replaces ad-hoc header implementations across the codebase for consistency and premium aesthetics.

### 1. Components
- **AtelierHeader (Main)**: Used for high-level screens like Home, Catalog, Customers, and History. Includes a built-in search bar slot.
- **AtelierHeaderSub (Sub)**: A more compact version for details/settings screens. Focuses on navigation and titles.
- **Sliver Versions**: `SliverAtelierHeader` and `SliverAtelierHeaderSub` are provided to ensure a unified experience when using `CustomScrollView`.

### 2. Design Standards (Typography)
- **Titles**: `32px`, `Manrope`, `FontWeight.w800`, white color, `-1` letter spacing.
- **Subtitles**: `14px`, `Outfit`, `FontWeight.normal`, `white70` color.

### 3. Layout & Spacing
- **Heights**: 
  - Main Header (Expanded): `175 + statusBarHeight + bottomHeight`.
  - Sub Header (Expanded): Dynamic based on content (~120-130 total).
- **Collision Rules**: 
  - Sub-headers use a `hideTopRow` flag when wrapped in `SliverAppBar` to prevent duplicate back buttons.
  - Added a `48px` top spacer in `AtelierHeaderSub` to clear the `SliverAppBar` leading leading slot.
- **Padding**: 
  - Main Header Search Bar bottom padding is set to `8px` for a tight, professional look.

### 4. Implementation Details
- Standardized the back button across all headers using `SolarIconsOutline.arrowLeft` with a subtle white background (`alpha: 0.1`) and `12px` border radius.
- Centralized `AppBar` gradients using `AppColors.headerGradient(context)`.

## Current State
- Codebase is clean according to `flutter analyze`.
- All major screens have been refactored to use this system.
- Overlap issues between titles and back buttons have been resolved via internal spacing adjustments.