import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/info_banner.dart';
import 'report_actions.dart';

/// Browse every report with search, filters and sorting.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.title = 'Campus reports'});

  final String title;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category; // null = all categories
  String? _status; // null = any status
  String _sort = 'newest'; // or 'affected'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _query.isNotEmpty || _category != null || _status != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _status = null;
    });
  }

  bool _matches(Incident incident) {
    if (_category != null && incident.category != _category) return false;
    if (_status != null && incident.status != _status) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return [
      incident.title,
      incident.description,
      incident.location,
      incident.locationDetail ?? '',
      incident.refCode,
      incident.categoryLabel,
    ].any((field) => field.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final scheme = Theme.of(context).colorScheme;

    final results = provider.allIncidents.where(_matches).toList();
    if (_sort == 'affected') {
      results.sort((a, b) {
        final byCount = b.affectedCount.compareTo(a.affectedCount);
        return byCount != 0 ? byCount : b.createdAt.compareTo(a.createdAt);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          // ---------- Search ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search reports, places or ALU-codes',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),

          // ---------- Category chips ----------
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                ...AppConstants.categories.map(
                  (c) => _CategoryChip(
                    label: c.label,
                    selected: _category == c.id,
                    onTap: () => setState(() => _category = c.id),
                  ),
                ),
              ],
            ),
          ),

          // ---------- Status filter and sort ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Filter by status',
                  onSelected: (value) =>
                      setState(() => _status = value == 'any' ? null : value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'any',
                      child: Text('Any status'),
                    ),
                    ...AppConstants.statuses.entries.map(
                      (e) => PopupMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  child: _Pill(
                    text:
                        'Status: ${_status == null ? 'Any' : AppConstants.statuses[_status]}',
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'newest', child: Text('Newest')),
                    PopupMenuItem(
                      value: 'affected',
                      child: Text('Most affected'),
                    ),
                  ],
                  child: _Pill(
                    text:
                        'Sort: ${_sort == 'newest' ? 'Newest' : 'Most affected'}',
                  ),
                ),
              ],
            ),
          ),

          // ---------- Results ----------
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.loadError != null) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: InfoBanner(
                      message: provider.loadError!,
                      type: InfoBannerType.error,
                    ),
                  );
                }
                if (results.isEmpty) {
                  return _EmptyResults(
                    hasFilters: _hasFilters,
                    onClear: _clearFilters,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
                  itemCount: results.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        '${results.length} ${results.length == 1 ? 'report' : 'reports'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    }
                    final incident = results[index - 1];
                    return IncidentCard(
                      incident: incident,
                      onTap: () => openReportDetails(context, incident.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: scheme.primary,
        backgroundColor: scheme.surface,
        side: BorderSide(color: selected ? scheme.primary : scheme.outline),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.onPrimary : scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, size: 18),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'No reports match' : 'No reports yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try a different search or clear the filters.'
                  : 'Reports from across campus will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
