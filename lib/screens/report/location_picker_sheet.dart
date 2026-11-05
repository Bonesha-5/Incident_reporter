import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Value returned when the place isn't in the list.
const String kSomewhereElse = 'Somewhere else';

/// Bottom sheet listing campus places, with search.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key, this.selected});

  final String? selected;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final places = AppConstants.campusLocations
        .where((p) => p.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      // moves the sheet up when the keyboard opens
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Choose a location',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search campus places',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...places.map((place) {
                  final isSelected = place == widget.selected;
                  return ListTile(
                    leading: Icon(
                      Icons.place_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                    title: Text(place),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: scheme.onPrimaryContainer,
                          )
                        : null,
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => Navigator.of(context).pop(place),
                  );
                }),
                ListTile(
                  leading: Icon(
                    Icons.add_location_alt_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                  title: const Text('Somewhere else (type it)'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.of(context).pop(kSomewhereElse),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
