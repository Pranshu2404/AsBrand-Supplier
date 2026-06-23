import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';

class BecomeSupplierScreen extends StatefulWidget {
  const BecomeSupplierScreen({super.key});

  @override
  State<BecomeSupplierScreen> createState() => _BecomeSupplierScreenState();
}

class _BecomeSupplierScreenState extends State<BecomeSupplierScreen> {
  int _currentStep = 0;

  // Store Info
  final _storeNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();

  // Registration Type
  String _registrationType = 'GST'; // 'GST' or 'Udyam'
  bool _isGstVerified = false;
  bool _isVerifyingGst = false;
  final _udyamController = TextEditingController();
  bool _isUdyamVerified = false;
  bool _isVerifyingUdyam = false;

  // Pickup Address
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Bank Details
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();

  bool _isSubmitting = false;
  bool _isFetchingPincode = false;

  // Cache the verification payload returned via verifyGst / verifyUdyam
  Map<String, dynamic>? _verificationData;

  // Step config
  final List<_StepConfig> _steps = [
    _StepConfig(icon: Icons.business, label: 'Business\nDetails'),
    _StepConfig(icon: Icons.location_on_outlined, label: 'Pickup\nAddress'),
    _StepConfig(icon: Icons.account_balance_outlined, label: 'Bank\nDetails'),
    _StepConfig(icon: Icons.person_outline, label: 'Supplier\nDetails'),
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _udyamController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────
  // PINCODE AUTO-FILL
  // ────────────────────────────────────────────────────────────────────
  Future<void> _fetchAddressFromPincode(String pincode) async {
    if (pincode.length != 6) return;
    setState(() => _isFetchingPincode = true);
    try {
      final url = Uri.parse('https://api.postalpincode.in/pincode/$pincode');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            final po = postOffices[0];
            if (mounted) {
              setState(() {
                _cityController.text = po['District'] ?? '';
                _stateController.text = po['State'] ?? '';
              });
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid pincode. Please enter city and state manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (_) {
      // Silently fail — user can fill manually
    } finally {
      if (mounted) setState(() => _isFetchingPincode = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // VALIDATION
  // ────────────────────────────────────────────────────────────────────
  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_storeNameController.text.trim().isEmpty) return 'Please enter your store/business name';
        if (_registrationType == 'GST') {
          if (_gstinController.text.trim().isEmpty) return 'Please enter GSTIN';
          if (!_isGstVerified) return 'Please verify your GSTIN to proceed';
        } else {
          if (_udyamController.text.trim().isEmpty) return 'Please enter Udyam Registration Number';
          if (!_isUdyamVerified) return 'Please verify your Udyam to proceed';
        }
        break;
      case 1:
        if (_buildingController.text.trim().isEmpty) return 'Please enter building/room number';
        if (_streetController.text.trim().isEmpty) return 'Please enter street/locality';
        if (_pincodeController.text.trim().isEmpty) return 'Please enter pincode';
        if (_pincodeController.text.trim().length != 6) return 'Pincode must be 6 digits';
        if (_cityController.text.trim().isEmpty) return 'Please enter city';
        if (_stateController.text.trim().isEmpty) return 'Please enter state';
        break;
      case 2:
        if (_accountNameController.text.trim().isEmpty) return 'Please enter account holder name';
        if (_accountNumberController.text.trim().isEmpty) return 'Please enter account number';
        if (_ifscController.text.trim().isEmpty) return 'Please enter IFSC code';
        if (_bankNameController.text.trim().isEmpty) return 'Please enter bank name';
        break;
    }
    return null;
  }

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade400),
      );
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _goToStep(int step) {
    if (step <= _currentStep) {
      setState(() => _currentStep = step);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // SUBMIT
  // ────────────────────────────────────────────────────────────────────
  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);

    try {
      final fullAddress = [
        _buildingController.text.trim(),
        _streetController.text.trim(),
        if (_landmarkController.text.trim().isNotEmpty) _landmarkController.text.trim(),
      ].join(', ');

      final data = {
        'storeName': _storeNameController.text.trim(),
        'gstin': _registrationType == 'GST' ? _gstinController.text.trim() : '',
        'gstVerified': _isGstVerified,
        'udyamRegistration': _registrationType == 'Udyam' ? _udyamController.text.trim() : '',
        'udyamVerified': _isUdyamVerified,
        if (_verificationData != null) 'verificationData': jsonEncode(_verificationData),
        'pickupAddress': {
          'address': fullAddress,
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'bankDetails': {
          'accountName': _accountNameController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'ifscCode': _ifscController.text.trim(),
          'bankName': _bankNameController.text.trim(),
        },
      };

      final response = await context.read<SupplierProvider>().registerAsSupplier(data);

      if (response['success'] == true && mounted) {
        // Save the new JWT token with role: 'supplier'
        final newToken = response['data']?['token'];
        if (newToken != null) {
          await context.read<AuthProvider>().updateToken(newToken);
        }
        await context.read<AuthProvider>().checkAuth();
        if (mounted) _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString().replaceAll('Exception:', '').trim()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // GST / UDYAM VERIFICATION
  // ────────────────────────────────────────────────────────────────────
  Future<void> _verifyGst() async {
    final gstin = _gstinController.text.trim();
    if (gstin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter GSTIN first')),
      );
      return;
    }
    setState(() => _isVerifyingGst = true);
    try {
      final res = await context.read<SupplierProvider>().verifyGst(gstin);
      if (res['success'] == true && mounted) {
        setState(() {
          _isGstVerified = true;
          if (res['verificationData'] != null) {
            _verificationData = jsonDecode(res['verificationData']);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GST Verified: ${res['data']}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() => _isGstVerified = false);
      }
    } finally {
      if (mounted) setState(() => _isVerifyingGst = false);
    }
  }

  Future<void> _verifyUdyam() async {
    final udyam = _udyamController.text.trim();
    if (udyam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Udyam Number first')),
      );
      return;
    }
    setState(() => _isVerifyingUdyam = true);
    try {
      final res = await context.read<SupplierProvider>().verifyUdyam(udyam);
      if (res['success'] == true && mounted) {
        setState(() {
          _isUdyamVerified = true;
          if (res['verificationData'] != null) {
            _verificationData = jsonDecode(res['verificationData']);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Udyam Verified: ${res['data']}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() => _isUdyamVerified = false);
      }
    } finally {
      if (mounted) setState(() => _isVerifyingUdyam = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // SUCCESS DIALOG
  // ────────────────────────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your application is under review.\nYou will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    // Logout so user can re-login with updated role once approved
                    context.read<AuthProvider>().logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'there';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            // Logout when going back (user chose not to complete supplier reg)
            context.read<AuthProvider>().logout();
          },
        ),
        title: const Text(
          'Become a Supplier',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Help?',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome banner (only on step 0)
          if (_currentStep == 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF6B21A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.shop, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $userName!',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete your supplier details to start selling',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Stepper ──
          _buildStepper(),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _buildStepContent(),
            ),
          ),

          // ── Bottom Bar ──
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // STEPPER
  // ────────────────────────────────────────────────────────────────────
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isCompleted = i < _currentStep;
          final isActive = i == _currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: () => _goToStep(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step indicator with connecting lines
                  Row(
                    children: [
                      // Left line
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted || isActive
                                ? AppTheme.successGreen
                                : Colors.grey.shade300,
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),

                      // Circle icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.successGreen
                              : isActive
                                  ? const Color(0xFFEDE9FE)
                                  : Colors.white,
                          border: Border.all(
                            color: isCompleted
                                ? AppTheme.successGreen
                                : isActive
                                    ? AppTheme.primaryAccent
                                    : Colors.grey.shade400,
                            width: isActive ? 2 : 1.5,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : Icon(
                                _steps[i].icon,
                                size: 18,
                                color: isActive
                                    ? AppTheme.primaryAccent
                                    : Colors.grey.shade500,
                              ),
                      ),

                      // Right line
                      if (i < _steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? AppTheme.successGreen
                                : Colors.grey.shade300,
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Label
                  Text(
                    _steps[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted
                          ? AppTheme.successGreen
                          : isActive
                              ? AppTheme.primaryAccent
                              : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // STEP CONTENT
  // ────────────────────────────────────────────────────────────────────
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBusinessDetails();
      case 1:
        return _buildPickupAddress();
      case 2:
        return _buildBankDetails();
      case 3:
        return _buildSupplierReview();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Business Details ──
  Widget _buildBusinessDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Enter your business/store details below',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        _buildFormField(
          label: 'Store / Business Name *',
          hint: 'e.g. Fashion Hub',
          controller: _storeNameController,
        ),
        const SizedBox(height: 20),
        const Text('Registration Type *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('GSTIN', style: TextStyle(fontSize: 14)),
                value: 'GST',
                groupValue: _registrationType,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _registrationType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Udyam', style: TextStyle(fontSize: 14)),
                value: 'Udyam',
                groupValue: _registrationType,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _registrationType = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_registrationType == 'GST') ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'GSTIN *',
                  hint: 'e.g. 22AAAAA0000A1Z5',
                  controller: _gstinController,
                  enabled: !_isGstVerified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ElevatedButton(
                    onPressed: _isGstVerified || _isVerifyingGst ? null : _verifyGst,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGstVerified ? AppTheme.successGreen : AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isVerifyingGst
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isGstVerified ? 'Verified ✓' : 'Verify',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'Udyam Registration Number *',
                  hint: 'e.g. UDYAM-XX-00-0000000',
                  controller: _udyamController,
                  enabled: !_isUdyamVerified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ElevatedButton(
                    onPressed: _isUdyamVerified || _isVerifyingUdyam ? null : _verifyUdyam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUdyamVerified ? AppTheme.successGreen : AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isVerifyingUdyam
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isUdyamVerified ? 'Verified ✓' : 'Verify',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _buildFormField(
          label: 'PAN Number (Optional)',
          hint: 'e.g. ABCDE1234F',
          controller: _panController,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  // ── Step 1: Pickup Address ──
  Widget _buildPickupAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pickup Address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Where should we pick up orders from?',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        _buildFormField(
          label: 'Room / Floor / Building Number *',
          hint: 'e.g. 01',
          controller: _buildingController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'Street / Locality *',
          hint: 'e.g. Kanpur Nagar',
          controller: _streetController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'Landmark',
          hint: 'e.g. Near City Hospital',
          controller: _landmarkController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'Pincode *',
          hint: 'e.g. 208010',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: _fetchAddressFromPincode,
        ),
        const SizedBox(height: 20),
        if (_isFetchingPincode)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Fetching city & state from pincode...',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'City *',
                hint: 'e.g. Kanpur',
                controller: _cityController,
                enabled: !_isFetchingPincode,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFormField(
                label: 'State *',
                hint: 'e.g. Uttar Pradesh',
                controller: _stateController,
                enabled: !_isFetchingPincode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: Bank Details ──
  Widget _buildBankDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bank Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('For receiving your payments',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        _buildFormField(
          label: 'Beneficiary Name *',
          hint: 'e.g. Nitin Kumar',
          controller: _accountNameController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'Account Number *',
          hint: 'e.g. 50100718078440',
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'Bank Name *',
          hint: 'e.g. HDFC Bank',
          controller: _bankNameController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          label: 'IFSC Code *',
          hint: 'e.g. HDFC0000240',
          controller: _ifscController,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  // ── Step 3: Review ──
  Widget _buildSupplierReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Your Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Verify all information before submitting',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 24),

        // Business Details
        _buildReviewSection(
          title: 'Business Details',
          onEdit: () => setState(() => _currentStep = 0),
          fields: [
            _ReviewField('Store Name', _storeNameController.text),
            if (_registrationType == 'GST')
              _ReviewField('GSTIN',
                  '$_registrationType: ${_gstinController.text} (${_isGstVerified ? 'Verified' : 'Unverified'})')
            else
              _ReviewField('Udyam Number',
                  '$_registrationType: ${_udyamController.text} (${_isUdyamVerified ? 'Verified' : 'Unverified'})'),
            if (_panController.text.isNotEmpty) _ReviewField('PAN', _panController.text),
          ],
        ),
        const SizedBox(height: 20),

        // Pickup Address
        _buildReviewSection(
          title: 'Pickup Address',
          onEdit: () => setState(() => _currentStep = 1),
          fields: [
            _ReviewField('Building', _buildingController.text),
            _ReviewField('Street', _streetController.text),
            if (_landmarkController.text.isNotEmpty) _ReviewField('Landmark', _landmarkController.text),
            _ReviewField('Pincode', _pincodeController.text),
            _ReviewField('City', _cityController.text),
            _ReviewField('State', _stateController.text),
          ],
        ),
        const SizedBox(height: 20),

        // Bank Details
        _buildReviewSection(
          title: 'Bank Details',
          onEdit: () => setState(() => _currentStep = 2),
          fields: [
            _ReviewField('Beneficiary', _accountNameController.text),
            _ReviewField('Account No.', _accountNumberController.text),
            _ReviewField('Bank Name', _bankNameController.text),
            _ReviewField('IFSC Code', _ifscController.text),
          ],
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ────────────────────────────────────────────────────────────────────

  /// Form field — clean style with label above
  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            counterText: '',
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Review section with left grey border, label/value pairs
  Widget _buildReviewSection({
    required String title,
    required VoidCallback onEdit,
    required List<_ReviewField> fields,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit',
                      style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          // Fields with left border indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
              ),
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.label,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              Text(f.value.isEmpty ? '—' : f.value,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ──
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: _currentStep == 3
          // Submit button on review step
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit & Become a Supplier',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          // Next + Back on form steps
          : Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Helper classes ──
class _StepConfig {
  final IconData icon;
  final String label;
  _StepConfig({required this.icon, required this.label});
}

class _ReviewField {
  final String label;
  final String value;
  _ReviewField(this.label, this.value);
}
