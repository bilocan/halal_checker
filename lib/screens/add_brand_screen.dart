import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../services/directory_service.dart';

class AddBrandScreen extends StatefulWidget {
  const AddBrandScreen({super.key});

  @override
  State<AddBrandScreen> createState() => _AddBrandScreenState();
}

class _AddBrandScreenState extends State<AddBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DirectoryService();
  bool _isSubmitting = false;

  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _certBodyCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  String _category = 'food';

  static const _categories = ['food', 'cosmetics', 'pharma', 'other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _certBodyCtrl.dispose();
    _websiteCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final ok = await _service.insertBrand(
      name: _nameCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      category: _category,
      certificationBody: _certBodyCtrl.text.trim().isEmpty
          ? null
          : _certBodyCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      logoUrl: _logoUrlCtrl.text.trim().isEmpty
          ? null
          : _logoUrlCtrl.text.trim(),
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
        title: const Text('Add Certified Brand'),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_nameCtrl, 'Brand Name', required: true),
            const SizedBox(height: 14),
            _field(_countryCtrl, 'Country', required: true),
            const SizedBox(height: 14),
            _categoryDropdown(),
            const SizedBox(height: 14),
            _field(_certBodyCtrl, 'Certification Body (optional)'),
            const SizedBox(height: 14),
            _field(
              _websiteCtrl,
              'Website (optional)',
              keyboard: TextInputType.url,
            ),
            const SizedBox(height: 14),
            _field(
              _logoUrlCtrl,
              'Logo URL (optional)',
              keyboard: TextInputType.url,
            ),
            const SizedBox(height: 28),
            _submitButton(),
          ],
        ),
      ),
    );
  }

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
                'Save Brand',
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
    'food' => 'Food',
    'cosmetics' => 'Cosmetics',
    'pharma' => 'Pharma',
    _ => 'Other',
  };
}
