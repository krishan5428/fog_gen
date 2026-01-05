import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/telephone_no_settings_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../../constants/app_colors.dart';
import '../../../core/data/pojo/panel_data.dart';
import '../../../core/responses/socket_repository.dart';
import '../../widgets/app_bar.dart';

class TelephoneNoSettingsPage extends StatelessWidget {
  final PanelData panelData;

  const TelephoneNoSettingsPage({super.key, required this.panelData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => TelephoneNoSettingsViewModel(
            socketRepository: SocketRepository(),
            panelData: panelData, // pass into VM if needed
          ),
      child: const _TelephoneNoSettingsView(),
    );
  }
}

class _TelephoneNoSettingsView extends StatefulWidget {
  const _TelephoneNoSettingsView();

  @override
  State<_TelephoneNoSettingsView> createState() =>
      _TelephoneNoSettingsViewState();
}

class _TelephoneNoSettingsViewState extends State<_TelephoneNoSettingsView> {
  late final TelephoneNoSettingsViewModel _vm;
  final List<TextEditingController> _controllers = List.generate(
    10,
    (_) => TextEditingController(),
  );

  bool _wasLoading = true;

  @override
  void initState() {
    super.initState();
    _vm = context.read<TelephoneNoSettingsViewModel>();
    _vm.addListener(_onVMUpdated);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVMUpdated);
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    if (!mounted) return;
    for (int i = 0; i < 10; i++) {
      final newValue = _vm.settings[i].number;
      if (_controllers[i].text != newValue) {
        _controllers[i].text = newValue;
      }
    }
  }

  void _onVMUpdated() {
    if (!mounted) return;

    if (_wasLoading && !_vm.isLoading) {
      _syncControllers();
    }
    _wasLoading = _vm.isLoading;

    switch (_vm.event) {
      case TelephoneSettingsEvent.settingsReverted:
        _syncControllers();
        break;

      case TelephoneSettingsEvent.showUpdateSuccessToast:
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text('Success'),
          description: Text(_vm.lastUpdateMessage),
          alignment: Alignment.center,
          autoCloseDuration: const Duration(seconds: 3),
        );
        _syncControllers();
        break;

      case TelephoneSettingsEvent.showUpdateFailedToast:
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Failed'),
          description: const Text('Could not update settings.'),
          alignment: Alignment.center,
        );
        break;

      case TelephoneSettingsEvent.showFetchFailedToast:
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text('Error'),
          description: const Text('Could not fetch settings.'),
          alignment: Alignment.center,
        );
        break;

      default:
        break;
    }

    _vm.resetEvent();
  }

  void _showConfirm({
    required String title,
    required String content,
    required VoidCallback onYes,
    bool destructive = false,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                child: const Text("No"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor:
                      destructive ? AppColors.greyDark : AppColors.colorPrimary,
                ),
                child: const Text("Yes"),
                onPressed: () {
                  Navigator.pop(context);
                  onYes();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TelephoneNoSettingsViewModel>(
      builder: (_, vm, __) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: CustomAppBar(pageName: 'Telephone Numbers', isFilter: false),
          body:
              vm.isLoading && _controllers[0].text.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 10,
                                itemBuilder: (_, i) {
                                  return _TelephoneRow(
                                    index: i,
                                    controller: _controllers[i],
                                    setting: vm.settings[i],
                                    onNumberChanged:
                                        (v) =>
                                            vm.updateLocalSetting(i, number: v),
                                    onTypeChanged:
                                        (t) =>
                                            vm.updateLocalSetting(i, type: t),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            vm.isUpdating
                                                ? null
                                                : () {
                                                  _showConfirm(
                                                    title: "Discard Changes?",
                                                    content:
                                                        "Your changes will not be saved.",
                                                    destructive: true,
                                                    onYes:
                                                        () =>
                                                            vm.cancelChanges(),
                                                  );
                                                },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColors.white,
                                          foregroundColor:
                                              AppColors.colorPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text("CANCEL"),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            vm.isUpdating
                                                ? null
                                                : () {
                                                  _showConfirm(
                                                    title: "Update All?",
                                                    content:
                                                        "Are you sure you want to update all 10 numbers?",
                                                    onYes:
                                                        () =>
                                                            vm.submitAllChanges(),
                                                  );
                                                },
                                        icon: const Icon(
                                          Icons.upload,
                                          size: 18,
                                        ),
                                        label: const Text("UPDATE"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.colorPrimaryDark,
                                          foregroundColor: AppColors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (vm.isUpdating)
                        Container(
                          color: Colors.black.withOpacity(0.2),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
        );
      },
    );
  }
}

class _TelephoneRow extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final TelephoneNumberSetting setting;
  final ValueChanged<String> onNumberChanged;
  final ValueChanged<AlertType> onTypeChanged;

  const _TelephoneRow({
    required this.index,
    required this.controller,
    required this.setting,
    required this.onNumberChanged,
    required this.onTypeChanged,
  });

  @override
  State<_TelephoneRow> createState() => _TelephoneRowState();
}

class _TelephoneRowState extends State<_TelephoneRow> {
  bool _dropdownEnabled = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _dropdownEnabled = widget.controller.text.length == 10;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;

    setState(() {
      _dropdownEnabled = text.length == 10;

      if (text.isEmpty) {
        _errorText = "Number required";
      } else if (text.length < 10) {
        _errorText = "Enter 10 digits";
      } else {
        _errorText = null;
      }
    });

    widget.onNumberChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                "Telephone ${widget.index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 8),

              // Row for number + dropdown
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: TextFormField(
                      controller: widget.controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FD),
                        hintText: "10-digit number",
                        suffixIcon:
                            widget.controller.text.isNotEmpty
                                ? IconButton(
                                  onPressed: () => widget.controller.clear(),
                                  icon: const Icon(Icons.close, size: 18),
                                )
                                : null,
                        prefixIcon: const Icon(Icons.phone, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    flex: 6,
                    child: DropdownButtonFormField<AlertType>(
                      isExpanded: true,
                      value: widget.setting.type,
                      items:
                          AlertType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _dropdownEnabled
                              ? (v) => widget.onTypeChanged(v!)
                              : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            _dropdownEnabled
                                ? const Color(0xFFF8F9FD)
                                : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
