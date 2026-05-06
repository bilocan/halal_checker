import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_colors.dart';
import '../services/directory_service.dart';

class AddStoreScreen extends StatefulWidget {
  const AddStoreScreen({super.key});

  @override
  State<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DirectoryService();
  bool _isSubmitting = false;

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _certBodyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _category = 'restaurant';

  // Tracks the map's current center as the user pans.
  // Null until the user first moves the map.
  LatLng? _pickedLocation;

  static const _categories = [
    'restaurant',
    'grocery',
    'butcher',
    'bakery',
    'other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _certBodyCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pan the map to your store location, then tap Confirm.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await _service.insertStore(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      category: _category,
      certificationBody: _certBodyCtrl.text.trim().isEmpty
          ? null
          : _certBodyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Certified Store'),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_nameCtrl, 'Store / Restaurant Name', required: true),
            const SizedBox(height: 14),
            _categoryDropdown(),
            const SizedBox(height: 14),
            _field(_addressCtrl, 'Address', required: true),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field(_cityCtrl, 'City', required: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_countryCtrl, 'Country', required: true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(_certBodyCtrl, 'Certification Body (optional)'),
            const SizedBox(height: 14),
            _field(
              _phoneCtrl,
              'Phone (optional)',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _field(
              _websiteCtrl,
              'Website (optional)',
              keyboard: TextInputType.url,
            ),
            const SizedBox(height: 24),
            _buildLocationPicker(),
            const SizedBox(height: 28),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  // ── Location picker ────────────────────────────────────────────────────────

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Location',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Pan the map to your store, then tap Confirm Location.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 260,
            child: _MapPicker(
              onLocationChanged: (loc) => setState(() => _pickedLocation = loc),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _locationConfirmRow(),
      ],
    );
  }

  Widget _locationConfirmRow() {
    return Row(
      children: [
        Expanded(
          child: _pickedLocation != null
              ? Row(
                  children: [
                    const Icon(Icons.location_on, color: kGreen, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                      '${_pickedLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: kGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  'No location selected',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
        ),
      ],
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _inputDecoration(label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required field' : null
          : null,
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: _inputDecoration('Category'),
      items: _categories
          .map(
            (c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) _category = v;
      },
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Save Store',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: kGreenSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGreen, width: 1.5),
    ),
  );

  String _categoryLabel(String cat) => switch (cat) {
    'restaurant' => 'Restaurant',
    'grocery' => 'Grocery',
    'butcher' => 'Butcher',
    'bakery' => 'Bakery',
    _ => 'Other',
  };
}

// ── Stateful map picker widget ─────────────────────────────────────────────
//
// Extracted so it can manage its own MapController without conflicting with
// the parent's scroll view.

class _MapPicker extends StatefulWidget {
  final ValueChanged<LatLng> onLocationChanged;

  const _MapPicker({required this.onLocationChanged});

  @override
  State<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<_MapPicker> {
  // Current center of the map (updated live as user pans).
  LatLng _center = const LatLng(20, 0);
  bool _hasInteracted = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 2,
            // Update center on every gesture-driven move.
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                _center = camera.center;
                if (!_hasInteracted) _hasInteracted = true;
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.halalscan',
            ),
            SimpleAttributionWidget(
              source: const Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
        // Crosshair — always at the visual center of the map.
        const Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_pin,
                  color: kGreen,
                  size: 40,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                ),
                // Half the icon height as dead space so the pin tip = map center.
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // "Confirm Location" button overlaid at the bottom.
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_hasInteracted) widget.onLocationChanged(_center);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasInteracted ? kGreen : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              _hasInteracted ? 'Confirm Location' : 'Pan map then confirm',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
