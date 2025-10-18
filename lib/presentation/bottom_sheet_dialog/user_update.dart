import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/viewModel/user_view_model.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateUserFieldBottomSheet extends StatefulWidget {
  final int userId;
  final String formKey; // "name", "mobile", "password", "email"
  final String? currentValue;

  const UpdateUserFieldBottomSheet({
    super.key,
    required this.userId,
    required this.formKey,
    this.currentValue,
  });

  @override
  State<UpdateUserFieldBottomSheet> createState() =>
      _UpdateUserFieldBottomSheetState();
}

class _UpdateUserFieldBottomSheetState
    extends State<UpdateUserFieldBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.formKey != "password") {
      _controller.text = widget.currentValue ?? "";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userViewModel = context.read<UserViewModel>();
    setState(() => _loading = true);

    try {
      switch (widget.formKey) {
        case "name":
          await userViewModel.updateUserName(widget.userId, _controller.text);
          break;
        case "mobile":
          await userViewModel.updateUserMobile(widget.userId, _controller.text);
          break;
        case "password":
          await userViewModel.updateUserPassword(
            widget.userId,
            _controller.text,
          );
          break;
        case "email":
          await userViewModel.updateUserEmail(widget.userId, _controller.text);
          break;
      }

      if (mounted) {
        CustomNavigation.instance.popWithResult(context: context, result: true);
        SnackBarHelper.showSnackBar(
          context,
          '${widget.formKey.toUpperCase()} updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update ${widget.formKey}")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Update ${widget.formKey.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.colorPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  obscureText: widget.formKey == "password",
                  decoration: InputDecoration(
                    labelText: "Enter ${widget.formKey}",
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter ${widget.formKey}";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.colorPrimary,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: _save,
                      child: const Text("Save"),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
