import 'package:flutter/material.dart';
import '../main.dart';
import '../services/database_service.dart';
import '../services/product_service.dart';
import '../localization/app_localizations.dart';
import '../widgets/halal_scan_logo.dart';
import 'result_screen.dart';
import 'home_screen.dart';

const _green = Color(0xFF2E7D32);
const _greenDark = Color(0xFF1B5E20);

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final scans = await DatabaseService.instance.getRecentScans();
    if (mounted) {
      setState(() {
        _recentScans = scans;
        _isLoading = false;
      });
    }
  }

  Future<void> _openScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    await _loadRecentScans();
  }

  Future<void> _openResult(Map<String, dynamic> scan) async {
    setState(() => _isLoadingProduct = true);
    try {
      final product = await _productService.getProduct(scan['barcode']);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            product: product,
            barcode: scan['barcode'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load product. Please check your connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    final loc = AppLocalizations.of(context);

    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';

    if (difference.inDays == 0) return '${loc.today}, $time';
    if (difference.inDays == 1) return '${loc.yesterday}, $time';
    if (difference.inDays < 7) return '${loc.daysAgo(difference.inDays)}, $time';

    final y = date.year;
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$mo-$d, $time';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.startTitle),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              HalalCheckerApp.of(context)?.setLocale(Locale(value));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Text(localizations.english),
              ),
              PopupMenuItem(
                value: 'tr',
                child: Text(localizations.turkish),
              ),
              PopupMenuItem(
                value: 'de',
                child: Text(localizations.german),
              ),
            ],
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Logo + tagline header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_greenDark, _green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const HalalScanLogo(size: 72, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    localizations.tagline,
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 13,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Main scan button
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _green.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _openScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                    const SizedBox(height: 6),
                    Text(
                      localizations.scanButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Recent scans section
            Text(
              localizations.lastResults,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recentScans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.noRecentResults,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.noRecentResultsHint,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _recentScans.length,
                          itemBuilder: (context, index) {
                            final scan = _recentScans[index];
                            final isHalal = scan['isHalal'] as bool;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isHalal ? _green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  scan['productName'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${localizations.lastScanned}: ${_formatDate(scan['timestamp'] as int)}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openResult(scan),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
          if (_isLoadingProduct)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: _green),
              ),
            ),
        ],
      ),
    );
  }
}