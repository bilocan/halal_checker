import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../services/promo_announcement_service.dart';

/// Superadmin editor for the promo popup ([PromoAnnouncementService]).
class PromoSettingsCard extends StatefulWidget {
  const PromoSettingsCard({super.key});

  @override
  State<PromoSettingsCard> createState() => _PromoSettingsCardState();
}

class _PromoSettingsCardState extends State<PromoSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  final _imageCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _showInApp = false;
  bool _showOnWeb = false;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    _imageCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _imageCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final promo = await PromoAnnouncementService.fetch();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (promo != null) {
        _imageCtrl.text = promo.imageUrl ?? '';
        _linkCtrl.text = promo.linkUrl ?? '';
        _showInApp = promo.showInApp;
        _showOnWeb = promo.showOnWeb;
        _endsAt = promo.endsAt?.toLocal();
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _upload() async {
    final loc = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    final url = await PromoAnnouncementService.uploadImage(
      bytes: bytes,
      fileName: picked.name,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (url == null) {
      _snack(loc.promoUploadFailed);
      return;
    }
    _imageCtrl.text = url;
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
    // Inclusive: show through the end of the selected day (local time).
    setState(
      () => _endsAt = DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    String? clean(String s) => s.trim().isEmpty ? null : s.trim();
    final ok = await PromoAnnouncementService.update(
      imageUrl: clean(_imageCtrl.text),
      linkUrl: clean(_linkCtrl.text),
      showInApp: _showInApp,
      showOnWeb: _showOnWeb,
      endsAt: _endsAt,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _snack(ok ? loc.promoSaved : loc.systemSettingsSaveFailed);
  }

  String? _validateUrl(String? v, {required bool requiredWhenEnabled}) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) {
      return (requiredWhenEnabled && (_showInApp || _showOnWeb))
          ? AppLocalizations.of(context).promoInvalidUrl
          : null;
    }
    return PromoAnnouncementService.isValidHttpUrl(value)
        ? null
        : AppLocalizations.of(context).promoInvalidUrl;
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
    final imageUrl = _imageCtrl.text.trim();
    final busy = _saving || _uploading;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              if (PromoAnnouncementService.isValidHttpUrl(imageUrl))
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 180,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageCtrl,
                decoration: InputDecoration(labelText: loc.promoImageUrl),
                keyboardType: TextInputType.url,
                validator: (v) => _validateUrl(v, requiredWhenEnabled: true),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _upload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: Text(
                    _uploading ? loc.promoUploading : loc.promoUploadImage,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linkCtrl,
                decoration: InputDecoration(labelText: loc.promoLinkUrl),
                keyboardType: TextInputType.url,
                validator: (v) => _validateUrl(v, requiredWhenEnabled: true),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.promoShowInApp),
                value: _showInApp,
                activeThumbColor: kGreen,
                onChanged: busy ? null : (v) => setState(() => _showInApp = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.promoShowOnWeb),
                value: _showOnWeb,
                activeThumbColor: kGreen,
                onChanged: busy ? null : (v) => setState(() => _showOnWeb = v),
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
                onTap: busy ? null : _pickEndDate,
                trailing: _endsAt == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: busy
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
                onPressed: busy ? null : _save,
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
      ),
    );
  }
}
