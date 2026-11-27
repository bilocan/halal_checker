import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../services/events_service.dart';
import '../../services/promo_announcement_service.dart';
import '../events_screen.dart' show formatEventDates;

/// Superadmin editor for the promo popup: pick which event is featured.
/// Events themselves are created/edited in the web admin.
class PromoSettingsCard extends StatefulWidget {
  const PromoSettingsCard({super.key});

  @override
  State<PromoSettingsCard> createState() => _PromoSettingsCardState();
}

class _PromoSettingsCardState extends State<PromoSettingsCard> {
  bool _loading = true;
  bool _saving = false;
  List<AppEvent> _events = const [];
  String? _eventId;
  bool _showInApp = false;
  bool _showOnWeb = false;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PromoAnnouncementService.fetch(),
      EventsService.fetchAll(),
    ]);
    if (!mounted) return;
    final promo = results[0] as PromoAnnouncement?;
    final events = (results[1] as List<AppEvent>?) ?? const <AppEvent>[];
    final split = EventsSplit.from(events, DateTime.now());
    setState(() {
      _loading = false;
      _events = [...split.upcoming, ...split.past];
      if (promo != null) {
        _eventId = _events.any((e) => e.id == promo.eventId)
            ? promo.eventId
            : null;
        _showInApp = promo.showInApp;
        _showOnWeb = promo.showOnWeb;
        _endsAt = promo.endsAt?.toLocal();
      }
    });
  }

  AppEvent? get _selected {
    for (final e in _events) {
      if (e.id == _eventId) return e;
    }
    return null;
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  void _onEventChanged(String? id) {
    setState(() {
      _eventId = id;
      final ev = _selected;
      // Default "show until" to the last day of the chosen event.
      if (ev != null) _endsAt = _endOfDay(ev.lastAt.toLocal());
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endsAt ?? now.add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null) return;
    setState(() => _endsAt = _endOfDay(date));
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    if (_eventId == null && (_showInApp || _showOnWeb)) {
      _snack(loc.promoEventRequired);
      return;
    }
    setState(() => _saving = true);
    final ok = await PromoAnnouncementService.update(
      eventId: _eventId,
      showInApp: _showInApp,
      showOnWeb: _showOnWeb,
      endsAt: _endsAt,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _snack(ok ? loc.promoSaved : loc.systemSettingsSaveFailed);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selected = _selected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.promoSettingsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc.promoSettingsDescription,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _eventId,
              isExpanded: true,
              decoration: InputDecoration(labelText: loc.promoEvent),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(loc.promoNoEvent),
                ),
                for (final e in _events)
                  DropdownMenuItem<String?>(
                    value: e.id,
                    child: Text(
                      '${e.title} · ${formatEventDates(e, locale)}'
                      '${e.published ? '' : ' (draft)'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _saving ? null : _onEventChanged,
            ),
            const SizedBox(height: 4),
            Text(
              loc.promoManageEventsHint,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (selected?.imageUrl != null) ...[
              const SizedBox(height: 12),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: selected!.imageUrl!,
                    height: 180,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.promoShowInApp),
              value: _showInApp,
              activeThumbColor: kGreen,
              onChanged: _saving ? null : (v) => setState(() => _showInApp = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.promoShowOnWeb),
              value: _showOnWeb,
              activeThumbColor: kGreen,
              onChanged: _saving ? null : (v) => setState(() => _showOnWeb = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(loc.promoEndsAt),
              subtitle: Text(
                _endsAt == null
                    ? loc.promoNoEndDate
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(_endsAt!),
              ),
              onTap: _saving ? null : _pickEndDate,
              trailing: _endsAt == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _saving
                          ? null
                          : () => setState(() => _endsAt = null),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.promoResetHint,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: kGreen),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(loc.promoSave),
            ),
          ],
        ),
      ),
    );
  }
}
