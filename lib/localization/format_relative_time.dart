import 'app_localizations.dart';

/// Short relative timestamp for comments and admin lists.
String formatRelativeTime(AppLocalizations loc, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return loc.timeJustNow;
  if (diff.inHours < 1) return loc.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return loc.timeHoursAgo(diff.inHours);
  if (diff.inDays < 30) return loc.timeDaysAgo(diff.inDays);
  return '${dt.day}/${dt.month}/${dt.year}';
}
