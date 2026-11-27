import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../services/promo_announcement_service.dart';

/// Precaches the poster and shows it in a dialog. Tapping the poster opens
/// [PromoAnnouncement.linkUrl]. Any close marks the campaign as dismissed.
/// Does nothing if the image fails to load.
Future<void> showPromoAnnouncementDialog(
  BuildContext context,
  PromoAnnouncement promo,
) async {
  final imageUrl = promo.imageUrl;
  final linkUrl = promo.linkUrl;
  if (imageUrl == null || linkUrl == null) return;

  try {
    await precacheImage(CachedNetworkImageProvider(imageUrl), context);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => PromoAnnouncementDialog(
      imageUrl: imageUrl,
      onOpenLink: () async {
        Navigator.of(ctx).pop();
        final uri = Uri.tryParse(linkUrl);
        if (uri == null) return;
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('[Promo] launch failed: $e');
        }
      },
    ),
  );
  await PromoAnnouncementService.dismiss(promo.campaignId);
}

class PromoAnnouncementDialog extends StatelessWidget {
  const PromoAnnouncementDialog({
    super.key,
    required this.imageUrl,
    required this.onOpenLink,
  });

  final String imageUrl;
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Stack(
          children: [
            GestureDetector(
              key: const ValueKey('promo_image'),
              onTap: onOpenLink,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const ValueKey('promo_close'),
                tooltip: loc.close,
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
