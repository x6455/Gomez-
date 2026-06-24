import 'package:telebirrbybr7/screens/engage_page.dart';

class NameFormatter {
  /// Formats a name based on EngagePage checkbox and initial detection
  /// - If uppercase is unchecked → returns name as-is
  /// - If uppercase is checked AND has initial (Mr/Mrs/Miss/Dr/etc) → Title Case
  /// - If uppercase is checked AND no initial → ALL CAPS
  static String format(String name, String number) {
    // Check EngagePage checkbox
    bool shouldFormat = false;
    try {
      final account = globalEngageList.firstWhere(
        (a) => a['number'] == number,
      );
      shouldFormat = account['uppercase'] == 'true';
    } catch (_) {}

    if (!shouldFormat) return name;

    // Check for initials
    final initials = ['MR', 'MRS', 'MISS', 'MS', 'DR', 'PROF'];
    final words = name.trim().split(' ');

    if (words.isNotEmpty && initials.contains(words.first.toUpperCase())) {
      // Has initial → Title Case
      return words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    } else {
      // No initial → ALL CAPS
      return name.toUpperCase();
    }
  }
}