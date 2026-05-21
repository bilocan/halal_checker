import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/product.dart';
import '../services/analysis_service.dart';
import '../services/product_service.dart';
import 'result_screen.dart';

enum _Status { pending, loading, done, notFound, error }

class _Item {
  final String barcode;
  _Status status = _Status.pending;
  Product? product;

  _Item(this.barcode);
}

class BatchScanScreen extends StatefulWidget {
  const BatchScanScreen({super.key});

  @override
  State<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends State<BatchScanScreen> {
  final _productService = ProductService();
  List<_Item> _items = [];
  bool _processing = false;
  bool _done = false;
  int _doneCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndProcess());
  }

  Future<void> _pickAndProcess() async {
    final allowed = await AnalysisService().hasOperation('admin.batch_import');
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied: superadmin only')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final content = String.fromCharCodes(bytes);
    final barcodes = _parse(content);

    if (barcodes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid barcodes found in file')),
      );
      Navigator.pop(context);
      return;
    }

    setState(() {
      _items = barcodes.map(_Item.new).toList();
      _processing = true;
    });

    await _processAll();
  }

  List<String> _parse(String content) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in content.split(RegExp(r'[\r\n]+'))) {
      // Take first column of CSV lines
      final cell = raw.split(RegExp(r'[,;]')).first;
      final digits = cell.trim().replaceAll(RegExp(r'[^\d]'), '');
      if (RegExp(r'^\d{6,50}$').hasMatch(digits) && seen.add(digits)) {
        out.add(digits);
      }
    }
    return out;
  }

  Future<void> _processAll() async {
    const concurrency = 5;
    for (var i = 0; i < _items.length; i += concurrency) {
      final batch = _items.skip(i).take(concurrency).toList();
      await Future.wait(batch.map(_processOne));
    }
    if (mounted) {
      setState(() {
        _processing = false;
        _done = true;
      });
    }
  }

  Future<void> _processOne(_Item item) async {
    if (mounted) setState(() => item.status = _Status.loading);
    try {
      final product = await _productService.getProduct(item.barcode);
      if (mounted) {
        setState(() {
          item.product = product;
          item.status = product != null ? _Status.done : _Status.notFound;
          _doneCount++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          item.status = _Status.error;
          _doneCount++;
        });
      }
    }
  }

  int get _halalCount => _items.where((r) => r.product?.isHalal == true).length;
  int get _notHalalCount => _items
      .where((r) => r.status == _Status.done && r.product?.isHalal == false)
      .length;
  int get _unknownCount => _items
      .where((r) => r.status == _Status.done && (r.product?.isUnknown ?? false))
      .length;
  int get _notFoundCount => _items
      .where((r) => r.status == _Status.notFound || r.status == _Status.error)
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Import'),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : Column(
              children: [
                _SummaryBar(
                  total: _items.length,
                  done: _doneCount,
                  processing: _processing,
                  isDone: _done,
                  halal: _halalCount,
                  notHalal: _notHalalCount,
                  unknown: _unknownCount,
                  notFound: _notFoundCount,
                ),
                if (_processing)
                  LinearProgressIndicator(
                    value: _doneCount / _items.length,
                    backgroundColor: kGreenLight.withAlpha(80),
                    valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                    minHeight: 3,
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _ItemTile(
                      item: _items[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            product: _items[i].product,
                            barcode: _items[i].barcode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int total, done, halal, notHalal, unknown, notFound;
  final bool processing, isDone;

  const _SummaryBar({
    required this.total,
    required this.done,
    required this.processing,
    required this.isDone,
    required this.halal,
    required this.notHalal,
    required this.unknown,
    required this.notFound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade100,
      child: processing
          ? Text(
              'Processing $done / $total…',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$total barcodes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                _Chip(label: '$halal halal', color: kGreen),
                _Chip(label: '$notHalal not halal', color: Colors.red),
                if (unknown > 0)
                  _Chip(label: '$unknown unknown', color: kAmber),
                if (notFound > 0)
                  _Chip(label: '$notFound not found', color: Colors.grey),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final _Item item;
  final VoidCallback onTap;
  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    Widget leading;
    if (item.status == _Status.loading) {
      leading = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: kGreen),
      );
    } else if (item.status == _Status.done) {
      final halal = product?.isHalal ?? false;
      final unknown = product?.isUnknown ?? false;
      if (unknown) {
        leading = const Icon(Icons.help_outline, color: kAmber);
      } else {
        leading = Icon(
          halal ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: halal ? kGreen : Colors.red,
        );
      }
    } else {
      leading = const Icon(Icons.help_outline, color: Colors.grey);
    }

    final tappable =
        item.status == _Status.done || item.status == _Status.notFound;
    final name =
        product?.name ??
        (item.status == _Status.loading
            ? 'Loading…'
            : item.status == _Status.notFound
            ? 'Not found'
            : 'Error');

    return ListTile(
      leading: leading,
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.barcode,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: tappable
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: tappable ? onTap : null,
    );
  }
}
