# Search & Navigation Standardization

This conversation standardized the global search behavior and navigation fluidity in the ServisLog+ application.

## 1. Global Focus & State Management
- **Location**: `lib/features/main/main_screen.dart`
- **Pattern**: Inside the `onPageChanged` callback of the `PageView`, the following actions are performed:
    - **Keyboard Dismissal**: `FocusManager.instance.primaryFocus?.unfocus();`
    - **State Reset**: All search-related `StateProvider` and `StateNotifier` instances are reset to empty strings or default values to prevent "stale" search results when returning to a screen.
    - **Provider Reset**: 
        ```dart
        ref.read(homeSearchQueryProvider.notifier).state = '';
        ref.read(pelangganListProvider.notifier).updateSearch('');
        ref.read(stokListProvider.notifier).search('');
        ref.read(serviceMasterProvider.notifier).search('');
        ref.read(historySearchQueryProvider.notifier).state = '';
        ref.read(historySearchActiveProvider.notifier).state = false;
        ```

## 2. UI Synchronization (Controller Clearing)
- **Problem**: Even if providers are reset, the text remains in the `TextEditingController` of the search bars.
- **Solution**: 
    - Main screens (`HomeScreen`, `PelangganScreen`, `KatalogScreen`, `HistoryScreen`) use `ConsumerStatefulWidget` to own a `TextEditingController`.
    - Use `ref.listen(navigationProvider, ...)` in the `build` method to clear the controller when the user switches to a different tab index.
    - **Example**:
      ```dart
      ref.listen(navigationProvider, (previous, next) {
        if (next != CURRENT_TAB_INDEX) {
          _searchController.clear();
        }
      });
      ```

## 3. Localization & Bug Fixes
- **DateFormat Exception**: Screens using `DateFormat('...', 'id_ID')` (like `TransactionDetailScreen`) will crash with a white screen if the locale is not initialized.
- **Fix**: Added `initializeDateFormatting('id_ID', null)` to `lib/main.dart` inside the `main` function after `WidgetsFlutterBinding.ensureInitialized()`. This requires the `intl` package and `package:intl/date_symbol_data_local.dart`.

## 4. UI Consistency
- **AppBar Alignment**: Title colors should adapt to light/dark modes (Black/Dark in day, White in night).
- **HomeScreen Labels**: Standardized "HARI INI" to "OMSET HARI INI" for the Bento Grid dashboard.
- **Search Result Navigation**:
    - Tapping search results for customers/vehicles navigates to `PelangganDetailScreen`.
    - Tapping search results for history navigates to `TransactionDetailScreen`.
