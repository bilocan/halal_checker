import '../../localization/app_localizations.dart';

String formatRelativeDate(DateTime date, AppLocalizations loc) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) return loc.today;
  if (difference.inDays == 1) return loc.yesterday;
  if (difference.inDays < 7) return loc.daysAgo(difference.inDays);

  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
