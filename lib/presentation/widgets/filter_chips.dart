// presentation/widgets/filter_chips.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/report_provider.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sort options
            Row(
              children: [
                Text(
                  'Sort by:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip(
                          context,
                          'Newest',
                          'newest',
                          reportProvider.sortBy == 'newest',
                          reportProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildSortChip(
                          context,
                          'Trending',
                          'trending',
                          reportProvider.sortBy == 'trending',
                          reportProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildSortChip(
                          context,
                          'Highest Score',
                          'highest_score',
                          reportProvider.sortBy == 'highest_score',
                          reportProvider,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Filter by category
            Row(
              children: [
                Text(
                  'Filter:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context,
                          'All',
                          null,
                          reportProvider.filterByCategory == null,
                          reportProvider,
                        ),
                        const SizedBox(width: 8),
                        ...AppConstants.reportCategories
                            .take(5)
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(
                                  context,
                                  category,
                                  category,
                                  reportProvider.filterByCategory == category,
                                  reportProvider,
                                ),
                              ),
                            ),
                        if (AppConstants.reportCategories.length > 5)
                          _buildMoreFiltersButton(context, reportProvider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    String sortValue,
    bool isSelected,
    ReportProvider reportProvider,
  ) {
    return GestureDetector(
      onTap: () => reportProvider.setSortBy(sortValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.mediumGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String? filterValue,
    bool isSelected,
    ReportProvider reportProvider,
  ) {
    return GestureDetector(
      onTap: () => reportProvider.setFilterByCategory(filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.successGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.successGreen : AppTheme.mediumGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.mediumGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreFiltersButton(
    BuildContext context,
    ReportProvider reportProvider,
  ) {
    return GestureDetector(
      onTap: () => _showAllCategoriesBottomSheet(context, reportProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.mediumGray, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }

  void _showAllCategoriesBottomSheet(
    BuildContext context,
    ReportProvider reportProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Filter by Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 16),

                // Categories list
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildCategoryTile(
                        context,
                        'All Categories',
                        null,
                        reportProvider.filterByCategory == null,
                        reportProvider,
                      ),
                      const Divider(),
                      ...AppConstants.reportCategories.map(
                        (category) => _buildCategoryTile(
                          context,
                          category,
                          category,
                          reportProvider.filterByCategory == category,
                          reportProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    String title,
    String? value,
    bool isSelected,
    ReportProvider reportProvider,
  ) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.darkGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        reportProvider.setFilterByCategory(value);
        Navigator.pop(context);
      },
    );
  }
}
