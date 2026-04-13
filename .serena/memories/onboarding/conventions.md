# Conventions & Code Style
- Architecture: Feature-first/Layered Architecture (`core`, `data`, `domain`, `features`).
- State Management: Use Riverpod `Notifier` and `AsyncNotifier` (from `flutter_riverpod`).
- Data Access: Use `Repository` pattern for all data access. Use `Box` (from `objectbox`) inside repositories.
- Entities: Define `Entity` classes with ObjectBox annotations (`@Entity`, `@Id`, etc.).
- UI Components: Follow "Modern" UI guidelines. Use centralized themes in `app_theme.dart` and `app_colors.dart`.
- No Hardcoded Values: Use `AppColors`, `AppTheme`, and `AppIcons` exclusively.
- Reusability: Use `GlassCard`, `PremiumAppBar`, and individual feature-level reusable widgets.
- Clean Code: Follow logical naming conventions and ensure modularity.
- Analysis: Code must pass `flutter analyze` without warnings (excluding relevant generated code errors).
