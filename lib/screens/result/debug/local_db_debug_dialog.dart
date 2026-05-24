import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../services/cache_service.dart';
import '../../../services/product_service.dart';

Future<void> showLocalDbDebugDialog({
  required BuildContext context,
  required String barcode,
  required ProductService productService,
}) async {
  final loc = AppLocalizations.of(context);
  final cacheRaw = await CacheService().getRaw(barcode);
  final dbProduct = await productService.fetchFromSharedDbForDebug(barcode);

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final dialogLoc = AppLocalizations.of(ctx);
      return AlertDialog(
        title: Text(dialogLoc.localDbDebugTitle(barcode)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogLoc.debugCacheSection,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (cacheRaw == null)
                Text(
                  dialogLoc.debugEmpty,
                  style: const TextStyle(color: Colors.grey),
                )
              else
                _DebugField('isHalal', _jsonField(cacheRaw, 'isHalal')),
              if (cacheRaw != null)
                _DebugField('isUnknown', _jsonField(cacheRaw, 'isUnknown')),
              if (cacheRaw != null)
                _DebugField('isManaged', _jsonField(cacheRaw, 'isManaged')),
              if (cacheRaw != null)
                _DebugField(
                  'ingredients#',
                  _jsonListLen(cacheRaw, 'ingredients'),
                ),
              if (cacheRaw != null)
                _DebugField('_cachedAt', _jsonField(cacheRaw, '_cachedAt')),
              const SizedBox(height: 12),
              Text(
                dialogLoc.debugRemoteDbSection,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (dbProduct == null)
                Text(
                  dialogLoc.debugNotFound,
                  style: const TextStyle(color: Colors.grey),
                )
              else ...[
                _DebugField('isHalal', '${dbProduct.isHalal}'),
                _DebugField('isUnknown', '${dbProduct.isUnknown}'),
                _DebugField('isManaged', '${dbProduct.isManaged}'),
                _DebugField('ingredients#', '${dbProduct.ingredients.length}'),
                _DebugField(
                  'ingredients',
                  dbProduct.ingredients.take(5).join(', '),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await CacheService().removeProduct(barcode);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(loc.debugCacheCleared)));
              }
            },
            child: Text(dialogLoc.debugClearCache),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(dialogLoc.close),
          ),
        ],
      );
    },
  );
}

class _DebugField extends StatelessWidget {
  const _DebugField(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

String _jsonField(String raw, String key) {
  try {
    final m = (jsonDecode(raw) as Map<String, dynamic>);
    return '${m[key]}';
  } catch (_) {
    return '?';
  }
}

String _jsonListLen(String raw, String key) {
  try {
    final m = (jsonDecode(raw) as Map<String, dynamic>);
    final v = m[key];
    return v is List ? '${v.length}' : '?';
  } catch (_) {
    return '?';
  }
}
