import '../../localization/app_localizations.dart';

/// Formats a scan timestamp for the recent-scans list subtitle.
String formatScanDate(AppLocalizations loc, int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  final difference = now.difference(date);

  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  final time = '$hh:$mm';

  if (difference.inDays == 0) return '${loc.today}, $time';
  if (difference.inDays == 1) return '${loc.yesterday}, $time';
  if (difference.inDays < 7) {
    return '${loc.daysAgo(difference.inDays)}, $time';
  }

  final y = date.year;
  final mo = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$mo-$d, $time';
}
