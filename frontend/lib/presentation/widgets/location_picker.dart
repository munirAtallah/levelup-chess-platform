library;

import 'package:flutter/material.dart';
import '../../utils/jerusalem_locations.dart';
import '../../theme/app_theme.dart';

/// Shows a searchable dialog with kJerusalemLocations.
/// Returns the selected [JerusalemLocation] or null if dismissed.
Future<JerusalemLocation?> showLocationPicker(BuildContext context) async {
  String search = '';
  final langCode = Localizations.localeOf(context).languageCode;

  return showDialog<JerusalemLocation>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final filtered = kJerusalemLocations
            .where((l) => l.name(langCode)
                .toLowerCase()
                .contains(search.toLowerCase()))
            .toList();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          title: const Text('Select City', style: TextStyle(fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SizedBox(
              width: 320,
              height: 350,
              child: Column(
              children: [
                TextField(
                  autofocus: true,
                  onChanged: (val) => setDialogState(() => search = val),
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemExtent: 48,
                    itemBuilder: (_, i) => InkWell(
                      onTap: () => Navigator.pop(ctx, filtered[i]),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(filtered[i].name(langCode), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
              ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
            ),
          ],
        );
      },
    ),
  );
}
