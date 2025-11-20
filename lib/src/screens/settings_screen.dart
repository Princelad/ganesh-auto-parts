import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

/// Settings screen for configuring GST and business information
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessEmailController;
  late TextEditingController _gstinController;

  // Form state
  bool _gstEnabled = false;
  double _defaultGstRate = 18.0;
  bool _isLoading = false;
  bool _hasLoadedInitialData = false;
  int? _settingsId; // Store the settings ID

  // GST rate options
  final List<double> _gstRateOptions = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _businessAddressController = TextEditingController();
    _businessPhoneController = TextEditingController();
    _businessEmailController = TextEditingController();
    _gstinController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _gstinController.dispose();
    _hasLoadedInitialData = false;
    super.dispose();
  }

  /// Load settings into form
  void _loadSettingsIntoForm(AppSettings settings) {
    if (mounted) {
      setState(() {
        _settingsId = settings.id; // Store the ID
        _gstEnabled = settings.gstEnabled;
        _defaultGstRate = settings.defaultGstRate;
        _businessNameController.text = settings.businessName;
        _businessAddressController.text = settings.businessAddress ?? '';
        _businessPhoneController.text = settings.businessPhone ?? '';
        _businessEmailController.text = settings.businessEmail ?? '';
        _gstinController.text = settings.gstin ?? '';
      });
    }
  }

  /// Save settings
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settings = AppSettings(
        id: _settingsId, // Include the ID
        gstEnabled: _gstEnabled,
        defaultGstRate: _defaultGstRate,
        gstin: _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim(),
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty
            ? null
            : _businessAddressController.text.trim(),
        businessPhone: _businessPhoneController.text.trim().isEmpty
            ? null
            : _businessPhoneController.text.trim(),
        businessEmail: _businessEmailController.text.trim().isEmpty
            ? null
            : _businessEmailController.text.trim(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final success = await ref
          .read(settingsProvider.notifier)
          .updateSettings(settings);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(settingsProvider.notifier).loadSettings(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) {
          if (settings != null && !_hasLoadedInitialData) {
            // Load settings into form only once when screen opens
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasLoadedInitialData) {
                _loadSettingsIntoForm(settings);
                _hasLoadedInitialData = true;
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Information Section
                  Text(
                    'Business Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _businessPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _businessEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        // Basic email validation
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // GST Configuration Section
                  Text(
                    'GST Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Enable GST'),
                    subtitle: const Text('Apply GST to invoices'),
                    value: _gstEnabled,
                    onChanged: (value) {
                      setState(() {
                        _gstEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_gstEnabled) ...[
                    DropdownButtonFormField<double>(
                      initialValue: _defaultGstRate,
                      decoration: const InputDecoration(
                        labelText: 'Default GST Rate',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      items: _gstRateOptions.map((rate) {
                        return DropdownMenuItem(
                          value: rate,
                          child: Text('${rate.toStringAsFixed(0)}%'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _defaultGstRate = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _gstinController,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN (GST Identification Number)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                        hintText: 'e.g., 22AAAAA0000A1Z5',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                      ],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          // GSTIN must be 15 characters
                          if (value.trim().length != 15) {
                            return 'GSTIN must be exactly 15 characters';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Format: 2 digits (State Code) + 10 characters (PAN) + '
                      '1 character (Entity) + 1 character (Default Z) + 1 check digit',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSettings,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
