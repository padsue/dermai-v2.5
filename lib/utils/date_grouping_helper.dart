import 'package:intl/intl.dart';

class DateGroupingHelper {
  static Map<String, List<T>> groupItemsByDate<T>(
      List<T> items, DateTime Function(T item) getDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

    final Map<String, List<T>> groupedItems = {};

    for (final item in items) {
      final itemDate = getDate(item);
      final date = DateTime(itemDate.year, itemDate.month, itemDate.day);

      String groupKey;
      if (date.isAtSameMomentAs(today)) {
        groupKey = 'Today';
      } else if (date.isAtSameMomentAs(yesterday)) {
        groupKey = 'Yesterday';
      } else if (date.isAfter(startOfWeek)) {
        groupKey = 'This Week';
      } else if (date.isAfter(startOfLastWeek)) {
        groupKey = 'Last Week';
      } else if (date.year == now.year && date.month == now.month) {
        groupKey = 'This Month';
      } else {
        groupKey = DateFormat('MMMM yyyy').format(date);
      }

      if (groupedItems[groupKey] == null) {
        groupedItems[groupKey] = [];
      }
      groupedItems[groupKey]!.add(item);
    }

    return groupedItems;
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
