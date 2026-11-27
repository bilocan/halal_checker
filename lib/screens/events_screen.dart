import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../services/events_service.dart';
import 'result/widgets/result_product_images.dart';

/// Upcoming + past events (admin-managed in `events`).
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<AppEvent>?> _future;

  @override
  void initState() {
    super.initState();
    _future = EventsService.fetchPublished();
  }

  Future<void> _reload() async {
    final f = EventsService.fetchPublished();
    setState(() {
      _future = f;
    });
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.eventsTitle)),
      body: FutureBuilder<List<AppEvent>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data;
          if (events == null) {
            return _Message(
              text: loc.eventsLoadFailed,
              action: TextButton(
                onPressed: _reload,
                child: Text(loc.eventsRetry),
              ),
            );
          }
          final split = EventsSplit.from(events, DateTime.now());
          if (split.isEmpty) return _Message(text: loc.eventsEmpty);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (split.upcoming.isNotEmpty) ...[
                  _SectionTitle(loc.eventsUpcoming),
                  for (final e in split.upcoming) EventCard(event: e),
                ],
                if (split.past.isNotEmpty) ...[
                  _SectionTitle(loc.eventsPast),
                  for (final e in split.past) EventCard(event: e, past: true),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}

/// Formats the event's date (range) in the user's locale.
String formatEventDates(AppEvent e, String locale) {
  final date = DateFormat.yMMMd(locale);
  final time = DateFormat.Hm(locale);
  final start = e.startsAt.toLocal();
  final end = e.endsAt?.toLocal();
  if (end == null ||
      (end.year == start.year &&
          end.month == start.month &&
          end.day == start.day)) {
    return '${date.format(start)} · ${time.format(start)}';
  }
  return '${date.format(start)} – ${date.format(end)}';
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.past = false});

  final AppEvent event;
  final bool past;

  Future<void> _open() async {
    final uri = Uri.tryParse(event.linkUrl ?? '');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[EventCard] launch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final image = event.imageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Opacity(
        opacity: past ? 0.75 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null)
              GestureDetector(
                onTap: () => ResultProductImages.showFullscreen(
                  context,
                  url: image,
                  label: event.title,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ColoredBox(
                    color: Colors.grey.shade100,
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => const SizedBox(
                        height: 120,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formatEventDates(event, locale),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (event.linkUrl != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: TextButton.icon(
                    onPressed: _open,
                    style: TextButton.styleFrom(foregroundColor: kGreenDark),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(loc.eventsOpenLink),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
