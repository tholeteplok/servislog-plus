import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/history_provider.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/atelier_header.dart';
import '../../core/widgets/atelier_list_card.dart';
import '../home/transaction_detail_screen.dart';
import '../main/responsive_layout_builder.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Sync search controller with provider (e.g. when cleared via navigation)
    ref.listen(historySearchQueryProvider, (previous, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    final historyState = ref.watch(historyListProvider);
    final searchQuery = ref.watch(historySearchQueryProvider).toLowerCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic Filter based on search query
    final filteredItems = searchQuery.isEmpty
        ? historyState.items
        : historyState.items.where((item) {
            return item.title.toLowerCase().contains(searchQuery) ||
                item.subtitle.toLowerCase().contains(searchQuery) ||
                item.type.toLowerCase().contains(searchQuery) ||
                item.status.toLowerCase().contains(searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyListProvider.notifier).loadInitial(),
        color: AppColors.precisionViolet,
        displacement: 100,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAtelierHeader(
              title: AppStrings.history.title,
              subtitle: AppStrings.history.subtitle,
              showBackButton: false,
              searchController: _searchController,
              searchHint: AppStrings.history.searchHint,
              onSearchChanged: (val) =>
                  ref.read(historySearchQueryProvider.notifier).set(val),
              actions: [
                IconButton(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: Icon(
                    ref.watch(historyFilterNotifierProvider).dateRange != null ||
                            ref.watch(historyFilterNotifierProvider).type != 'ALL' ||
                            ref.watch(historyFilterNotifierProvider).paymentMethod != 'ALL'
                        ? SolarIconsBold.filter
                        : SolarIconsOutline.filter,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: AppStrings.common.filter,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),
            SliverToBoxAdapter(
              child: _buildActiveFilterChips(ref),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),
            if (filteredItems.isEmpty && !historyState.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        searchQuery.isEmpty
                            ? SolarIconsOutline.history
                            : SolarIconsOutline.magnifier,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty
                            ? AppStrings.history.noTransactions
                            : AppStrings.history.noResultsFor(searchQuery),
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredItems[index];
                    return _HistoryCard(item: item);
                  }, childCount: filteredItems.length),
                ),
              ),

            if (historyState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.precisionViolet),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(WidgetRef ref) {
    final filter = ref.watch(historyFilterNotifierProvider);
    if (filter.dateRange == null &&
        filter.type == 'ALL' &&
        filter.paymentMethod == 'ALL') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filter.dateRange != null)
              _buildChip(
                '${DateFormat('dd MMM').format(filter.dateRange!.start)} - ${DateFormat('dd MMM').format(filter.dateRange!.end)}',
                () => ref
                    .read(historyFilterNotifierProvider.notifier)
                    .update((s) => s.copyWith(clearDateRange: true)),
              ),
            if (filter.type != 'ALL')
              _buildChip(
                filter.type,
                () => ref
                    .read(historyFilterNotifierProvider.notifier)
                    .update((s) => s.copyWith(type: 'ALL')),
              ),
            if (filter.paymentMethod != 'ALL')
              _buildChip(
                filter.paymentMethod,
                () => ref
                    .read(historyFilterNotifierProvider.notifier)
                    .update((s) => s.copyWith(paymentMethod: 'ALL')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterNotifierProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.history.filterTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(historyFilterNotifierProvider.notifier).setFilter(
                        HistoryFilter()),
                child: Text(AppStrings.common.reset),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterLabel(AppStrings.history.selectDate),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
                initialDateRange: filter.dateRange,
              );
              if (range != null) {
                ref
                    .read(historyFilterNotifierProvider.notifier)
                    .update((s) => s.copyWith(dateRange: range));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   const Icon(SolarIconsOutline.calendar, color: Colors.grey),
                   const SizedBox(width: 12),
                   Text(
                     filter.dateRange == null
                         ? AppStrings.history.selectDate
                         : '${DateFormat('dd/MM/yyyy').format(filter.dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(filter.dateRange!.end)}',
                     style: TextStyle(
                       color: filter.dateRange == null
                           ? Colors.grey
                           : theme.colorScheme.onSurface,
                     ),
                   ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFilterLabel(AppStrings.history.transactionType),
          const SizedBox(height: 8),
          _buildChoiceRow(
            ref,
            ['ALL', 'SERVIS', 'PRODUK'],
            filter.type,
            (val) => ref
                .read(historyFilterNotifierProvider.notifier)
                .update((s) => s.copyWith(type: val)),
          ),
          const SizedBox(height: 24),
          _buildFilterLabel(AppStrings.history.paymentMethod),
          const SizedBox(height: 8),
          _buildChoiceRow(
            ref,
            ['ALL', 'Tunai', 'QRIS', 'Transfer'],
            filter.paymentMethod,
            (val) => ref
                .read(historyFilterNotifierProvider.notifier)
                .update((s) => s.copyWith(paymentMethod: val)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.precisionViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppStrings.history.applyFilter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildChoiceRow(
    WidgetRef ref,
    List<String> options,
    String selected,
    Function(String) onSelected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt == 'ALL'
                  ? AppStrings.history.all
                  : (opt == 'SERVIS'
                      ? AppStrings.history.typeService
                      : (opt == 'PRODUK' ? AppStrings.history.typeProduct : opt))),
              selected: isSelected,
              onSelected: (val) => val ? onSelected(opt) : null,
              selectedColor: AppColors.precisionViolet.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.precisionViolet : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final HistoryItemData item;

  const _HistoryCard({required this.item});

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isService = item.type == 'SERVICE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AtelierListGroup(
        children: [
          AtelierListTile(
            icon: item.icon,
            iconColor: isService ? AppColors.precisionViolet : Colors.blue,
            customTitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isService ? AppColors.precisionViolet : Colors.blue)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.type == 'SERVICE'
                            ? AppStrings.history.typeService
                            : AppStrings.history.typeProduct,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isService ? AppColors.precisionViolet : Colors.blue,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(item.date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            subtitle: item.subtitle,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(item.amount),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.precisionViolet
                        : AppColors.precisionViolet.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            onTap: isService
                ? () {
                    final container = ProviderScope.containerOf(context);
                    final trxListAsync = container.read(transactionListProvider);
                    final trxList = trxListAsync.value ?? [];
                    try {
                      final trx = trxList.firstWhere((t) => t.uuid == item.id);
                      AdaptiveNavigator.push(
                        context: context,
                        ref: ref,
                        detailContent: TransactionDetailScreen(transaction: trx),
                        routeBuilder: () =>
                            TransactionDetailScreen(transaction: trx),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.history.detailNotFound),
                        ),
                      );
                    }
                  }
                : () {},
          ),
        ],
      ),
    );
  }
}
