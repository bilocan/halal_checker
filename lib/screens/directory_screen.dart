import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../models/halal_brand.dart';
import '../models/halal_store.dart';
import '../services/directory_service.dart';
import 'add_brand_screen.dart';
import 'add_store_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DirectoryService _service = DirectoryService();
  final MapController _mapController = MapController();

  List<HalalBrand> _brands = [];
  List<HalalStore> _stores = [];
  bool _isLoading = true;

  final TextEditingController _brandSearch = TextEditingController();
  String _brandCategory = 'all';

  final TextEditingController _storeSearch = TextEditingController();
  String _storeCategory = 'all';
  bool _showMap = false;
  HalalStore? _selectedStore;

  static const _brandCategories = [
    'all',
    'food',
    'cosmetics',
    'pharma',
    'other',
  ];
  static const _storeCategories = [
    'all',
    'restaurant',
    'grocery',
    'butcher',
    'bakery',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _brandSearch.clear();
          _storeSearch.clear();
          _selectedStore = null;
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brandSearch.dispose();
    _storeSearch.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _service.fetchBrands(),
      _service.fetchStores(),
    ]);
    if (mounted) {
      setState(() {
        _brands = results[0] as List<HalalBrand>;
        _stores = results[1] as List<HalalStore>;
        _isLoading = false;
      });
    }
  }

  List<HalalBrand> get _filteredBrands {
    final q = _brandSearch.text.toLowerCase();
    return _brands.where((b) {
      final matchesSearch =
          q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.country.toLowerCase().contains(q) ||
          (b.certificationBody?.toLowerCase().contains(q) ?? false);
      final matchesCat =
          _brandCategory == 'all' || b.category == _brandCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  List<HalalStore> get _filteredStores {
    final q = _storeSearch.text.toLowerCase();
    return _stores.where((s) {
      final matchesSearch =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          s.country.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q);
      final matchesCat =
          _storeCategory == 'all' || s.category == _storeCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  String _categoryLabel(String cat) => switch (cat) {
    'all' => 'All',
    'food' => 'Food',
    'cosmetics' => 'Cosmetics',
    'pharma' => 'Pharma',
    'restaurant' => 'Restaurant',
    'grocery' => 'Grocery',
    'butcher' => 'Butcher',
    'bakery' => 'Bakery',
    _ => 'Other',
  };

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halal Directory'),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.verified), text: 'Brands'),
            Tab(icon: Icon(Icons.store), text: 'Stores'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? added;
          if (_tabController.index == 0) {
            added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddBrandScreen()),
            );
          } else {
            added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddStoreScreen()),
            );
          }
          if (added == true) _loadData();
        },
        backgroundColor: kGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Brand' : 'Add Store',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : TabBarView(
              controller: _tabController,
              children: [_buildBrandsTab(), _buildStoresTab()],
            ),
    );
  }

  // ── Brands tab ────────────────────────────────────────────────────────────

  Widget _buildBrandsTab() {
    final brands = _filteredBrands;
    return Column(
      children: [
        _buildSearchBar(
          _brandSearch,
          'Search brands, countries…',
          () => setState(() {}),
        ),
        _buildFilterChips(
          _brandCategories,
          _brandCategory,
          (cat) => setState(() => _brandCategory = cat),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: brands.isEmpty
              ? _buildEmptyState(
                  Icons.verified_outlined,
                  'No certified brands found',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: brands.length,
                  itemBuilder: (_, i) => _buildBrandCard(brands[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildBrandCard(HalalBrand brand) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logoBox(brand.logoUrl, Icons.verified),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          brand.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(brand.category),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    brand.country,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (brand.certificationBody != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      brand.certificationBody!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  if (brand.website != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _launchUrl(brand.website!),
                      child: Text(
                        brand.website!,
                        style: const TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stores tab ────────────────────────────────────────────────────────────

  Widget _buildStoresTab() {
    final stores = _filteredStores;
    return Column(
      children: [
        _buildSearchBar(
          _storeSearch,
          'Search stores, cities…',
          () => setState(() => _selectedStore = null),
        ),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: _buildFilterChips(
                  _storeCategories,
                  _storeCategory,
                  (cat) => setState(() {
                    _storeCategory = cat;
                    _selectedStore = null;
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildMapToggle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: stores.isEmpty
              ? _buildEmptyState(
                  Icons.store_outlined,
                  'No certified stores found',
                )
              : _showMap
              ? _buildMap(stores)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: stores.length,
                  itemBuilder: (_, i) => _buildStoreCard(stores[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildMapToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, icon: Icon(Icons.list, size: 18)),
        ButtonSegment(value: true, icon: Icon(Icons.map_outlined, size: 18)),
      ],
      selected: {_showMap},
      onSelectionChanged: (s) => setState(() {
        _showMap = s.first;
        _selectedStore = null;
      }),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : kGreen,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? kGreen
              : Colors.transparent,
        ),
        side: WidgetStateProperty.all(const BorderSide(color: kGreenLight)),
      ),
    );
  }

  Widget _buildMap(List<HalalStore> stores) {
    final center = stores.isNotEmpty
        ? LatLng(
            stores.map((s) => s.latitude).reduce((a, b) => a + b) /
                stores.length,
            stores.map((s) => s.longitude).reduce((a, b) => a + b) /
                stores.length,
          )
        : const LatLng(20, 0);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: stores.length == 1 ? 13 : 5,
            onTap: (tapPos, point) => setState(() => _selectedStore = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.halalscan',
            ),
            MarkerLayer(
              markers: stores.map((store) {
                final isSelected = _selectedStore?.id == store.id;
                return Marker(
                  point: LatLng(store.latitude, store.longitude),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStore = store);
                      _mapController.move(
                        LatLng(store.latitude, store.longitude),
                        _mapController.camera.zoom < 10
                            ? 13
                            : _mapController.camera.zoom,
                      );
                    },
                    child: Icon(
                      Icons.location_pin,
                      color: isSelected ? kAmber : kGreen,
                      size: isSelected ? 44 : 36,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black26),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SimpleAttributionWidget(
              source: const Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
        if (_selectedStore != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildStoreCard(_selectedStore!, elevated: true),
          ),
      ],
    );
  }

  Widget _buildStoreCard(HalalStore store, {bool elevated = false}) {
    return Card(
      elevation: elevated ? 6 : 1,
      margin: elevated ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logoBox(store.logoUrl, Icons.store),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(store.category),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${store.address}, ${store.city}, ${store.country}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 2,
                  ),
                  if (store.certificationBody != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      store.certificationBody!,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                  if (store.phone != null || store.website != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (store.phone != null)
                          _actionButton(
                            Icons.phone,
                            store.phone!,
                            () => _launchPhone(store.phone!),
                          ),
                        if (store.website != null)
                          _actionButton(
                            Icons.language,
                            'Website',
                            () => _launchUrl(store.website!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildSearchBar(
    TextEditingController ctrl,
    String hint,
    VoidCallback onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: ctrl,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    ctrl.clear();
                    onChanged();
                  },
                )
              : null,
          filled: true,
          fillColor: kGreenSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    List<String> categories,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final cat = categories[i];
        final isSelected = cat == selected;
        return FilterChip(
          label: Text(_categoryLabel(cat)),
          selected: isSelected,
          onSelected: (_) => onSelect(cat),
          selectedColor: kGreen,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
          ),
          checkmarkColor: Colors.white,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon — we\'re adding more.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _logoBox(String? logoUrl, IconData fallback) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: kGreenSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(fallback, color: kGreen, size: 28),
              ),
            )
          : Icon(fallback, color: kGreen, size: 28),
    );
  }

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kGreenSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _categoryLabel(category),
        style: const TextStyle(
          color: kGreenDark,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: kGreenLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: kGreen),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: kGreen, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
