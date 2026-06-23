import 'package:flutter/material.dart';

import '../services/product_service.dart';
import 'result_screen.dart';

class DeepLinkProductScreen extends StatefulWidget {
  final String barcode;
  const DeepLinkProductScreen({super.key, required this.barcode});

  @override
  State<DeepLinkProductScreen> createState() => _DeepLinkProductScreenState();
}

class _DeepLinkProductScreenState extends State<DeepLinkProductScreen> {
  final _service = ProductService();

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    final product = await _service.getProduct(widget.barcode);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(product: product, barcode: widget.barcode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
