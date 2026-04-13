# Statistics Screen Implementation (v1)

This memory documents the implementation of the comprehensive analytical dashboard for ServisLog+.

## 1. Overview
- **Entry Point**: Home Screen Bento Grid -> "Omzet" card.
- **Location**: `lib/features/statistik/statistik_screen.dart`.
- **Theme**: Premium Amethyst (Glassmorphism, gradients, Lucide icons).

## 2. Data Aggregation (`StatsNotifier`)
- **Location**: `lib/core/providers/stats_provider.dart`.
- **Logic**: Aggregates `Transaction` and `Sale` records from ObjectBox to calculate:
    - Daily, Weekly, and Monthly Revenue (Omzet).
    - Total Profit (Laba).
    - Today's Visitor Count and Active Services.
    - Top Services/Products Leaderboards.
    - Staff (Mekanik) Performance.
- **Provider**: `statsProvider` (StateNotifier).

## 3. Screen Structure & Tabs
The screen uses a `TabController` with 4 sections:
1. **Ringkasan**: 
    - Summary cards for Omzet & Laba.
    - Interactive 30-day revenue trend chart using `fl_chart`.
2. **Layanan**: Rankings of top services provided.
3. **Produk**: Rankings of top parts/products sold.
4. **Mekanik**: Performance metrics per staff member.

## 4. Privacy Mode
- **Feature**: Users can toggle visibility of sensitive financial data (Omzet/Laba values).
- **Implementation**: `_isPrivate` boolean in `StatistikScreen`.
- **Effect**: Replaces values with "Rp ••••••" when enabled.

## 5. UI Standardization
- **Header**: Large Amethyst gradient header with back button and privacy toggle.
- **Colors**: Uses `AppColors.darkBackground` for consistency with the Midnight Palette.
- **Icons**: Standardized on `LucideIcons`.
