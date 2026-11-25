// ignore_for_file: deprecated_member_use
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/core/utils/toast_helper.dart';
import '../../../core/data/pojo/panel_data.dart';
import '../../../presentation/widgets/app_bar.dart';
import '../repository/fourg_repository.dart';

class FourGMqttZoneMappingsScreen extends StatefulWidget {
  const FourGMqttZoneMappingsScreen({
    super.key,
    required this.panelData,
    required this.fourGRepository,
  });

  final PanelData panelData;
  final FourGRepository fourGRepository;

  @override
  State<FourGMqttZoneMappingsScreen> createState() =>
      _FourGMqttZoneMappingsScreenState();
}

class _FourGMqttZoneMappingsScreenState
    extends State<FourGMqttZoneMappingsScreen> {
  static const _inputNumbers = ["001", "002", "003", "004"];

  final _nameController = TextEditingController();

  List<String> _quickNames = List.generate(
    _inputNumbers.length,
    (i) => 'Input ${i + 1}',
  );
  List<bool> _quickEnabled = List.filled(_inputNumbers.length, true);

  int _selectedIndex = 0;
  bool _enabled = true;
  bool _isLoadingSummary = true;
  bool _isSaving = false;

  bool get _isBusy => _isLoadingSummary || _isSaving;

  @override
  void initState() {
    super.initState();
    // Manual load: only fires once this screen is actually opened.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ToastHelper.show(context, message);
  }

  void _applySelection(int index) {
    _selectedIndex = index;
    _nameController.text = _quickNames[index];
    _enabled = _quickEnabled[index];
  }

  /// Fast, single-round-trip load of every input's name and enabled state
  /// off the Dashboard summary (packet 001) — one request instead of
  /// reading each input's full settings (packet 010) individually, so
  /// switching between inputs in the dropdown is instant. The full 010
  /// record is only ever read again right before a Save, since 001 doesn't
  /// carry every field a write needs to echo back.
  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _isLoadingSummary = true);

    try {
      final summary = await widget.fourGRepository.readDashboardInputSummary(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
        zoneCount: _inputNumbers.length,
      );

      if (!mounted) return;

      if (summary != null) {
        setState(() {
          _quickNames = summary.names;
          _quickEnabled = summary.enabled;
          _applySelection(_selectedIndex);
        });
      } else {
        _showFeedback("Could not read input names from device.");
      }
    } catch (e) {
      _showFeedback("Error reading zone mapping: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _saveInput() async {
    if (_isBusy) return;

    final targetIndex = _selectedIndex;
    final newName = _nameController.text.trim();
    final isValid = RegExp(r'^[a-zA-Z0-9 ]{1,15}$').hasMatch(newName);
    if (!isValid) {
      _showFeedback('Only letters, numbers, and spaces allowed (max 15 chars)');
      return;
    }
    final newEnabled = _enabled;

    setState(() => _isSaving = true);
    ProgressDialog.show(context, message: "Saving Input ${targetIndex + 1}...");
    try {
      // Fetch the authoritative full record right before writing, so every
      // other field gets echoed back exactly as the panel currently has it.
      final settings = await widget.fourGRepository.readInputSettings(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
        inputNumber: _inputNumbers[targetIndex],
      );

      if (!mounted) return;

      if (settings == null) {
        _showFeedback("Could not read Input ${targetIndex + 1} before saving.");
        return;
      }

      final success = await widget.fourGRepository.writeInputSettings(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
        currentSettings: settings,
        newInputName: newName,
        newEnabled: newEnabled ? "1" : "0",
      );

      if (!mounted) return;

      if (success) {
        _showFeedback("Input ${targetIndex + 1} updated successfully.");
        setState(() {
          _quickNames[targetIndex] = newName;
          _quickEnabled[targetIndex] = newEnabled;
        });
      } else {
        _showFeedback("Failed to update Input ${targetIndex + 1} on device.");
      }
    } catch (e) {
      _showFeedback("Error saving Input ${targetIndex + 1}: $e");
    } finally {
      ProgressDialog.dismiss(context);
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is2Zone = widget.panelData.panelName.toUpperCase().contains(
      '2 ZONE',
    );
    final int zoneCount = is2Zone ? 2 : _inputNumbers.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        pageName: 'Zone Mapping',
        isFilter: false,
        isDash: false,
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSiteCard(),
              const SizedBox(height: 16),
              _buildInputDropdown(zoneCount),
              const SizedBox(height: 16),
              Expanded(child: _buildForm()),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.colorPrimary.withValues(alpha: 
                      0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isBusy ? null : _saveInput,
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.litePrimary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.litePrimary),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: AppColors.colorPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SITE NAME',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.colorPrimary,
                    letterSpacing: 0.5,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.panelData.siteName.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputDropdown(int zoneCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedIndex,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.colorPrimary,
          ),
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
            color: Colors.black87,
          ),
          items: List.generate(
            zoneCount,
            (i) => DropdownMenuItem(value: i, child: Text('Input ${i + 1}')),
          ),
          onChanged:
              _isBusy
                  ? null
                  : (val) {
                    if (val != null && val != _selectedIndex) {
                      setState(() => _applySelection(val));
                    }
                  },
        ),
      ),
    );
  }

  Widget _buildForm() {
    if (_isBusy && !_isSaving) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.colorPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading zone mapping...',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Input ${_selectedIndex + 1} Name',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  color: Colors.black45,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _nameController,
                enabled: !_isSaving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                ],
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.colorPrimary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _enabled ? 'Input Enabled' : 'Input Disabled',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    activeThumbColor: AppColors.colorPrimary,
                    onChanged:
                        _isSaving ? null : (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
