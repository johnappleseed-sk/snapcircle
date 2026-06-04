class DateFormatter {
  const DateFormatter._();

  static String timeAgo(DateTime? date) {
    if (date == null) {
      return '';
    }

    final difference = DateTime.now().difference(date.toLocal());

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final weeks = difference.inDays ~/ 7;
    if (weeks < 5) {
      return '${weeks}w ago';
    }

    final months = difference.inDays ~/ 30;
    if (months < 12) {
      return '${months}mo ago';
    }

    final years = difference.inDays ~/ 365;
    return '${years}y ago';
  }
}
