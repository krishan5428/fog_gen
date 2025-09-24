import 'package:drift/drift.dart' as drift;
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/viewModel/complaint_view_model.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/vertical_gap.dart';
import 'complaint_history.dart';

class AddComplaintPage extends StatefulWidget {
  const AddComplaintPage({super.key});

  @override
  State<AddComplaintPage> createState() => _AddComplaintPageState();
}

class _AddComplaintPageState extends State<AddComplaintPage> {
  List<String> siteNames = [];
  final List<ImageProvider?> uploadedImages = [null, null, null];
  String? selectedSite;
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController complaintController = TextEditingController();
  int? userId;
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    userId = await SharedPreferenceHelper.getUserId();
    if (userId != null) {
      await _loadPanelSiteNames();
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    complaintController.dispose();
    super.dispose();
  }

  Future<void> _loadPanelSiteNames() async {
    final panel = context.read<PanelViewModel>();
    final panels = await panel.getAllPanelWithUserId(userId!);
    setState(() {
      siteNames = panels.map((panel) => panel.siteName).toList();
    });
  }

  Future<void> _addComplaint() async {
    final formattedDateTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
    final addComplaintVM = context.read<ComplaintViewModel>();

    final subject = subjectController.text.trim();
    final complaint = complaintController.text.trim();

    if (userId == null ||
        selectedSite == null ||
        subject.isEmpty ||
        complaint.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields.")));
      return;
    }

    debugPrint('User ID: $userId');
    debugPrint('Site: $selectedSite');
    debugPrint('Subject: $subject');
    debugPrint('Complaint: $complaint');
    debugPrint(
      'Images: ${uploadedImages.where((img) => img != null).length} uploaded',
    );

    final complaintData = ComplaintTableCompanion(
      userId: drift.Value(userId! as String),
      siteName: drift.Value(selectedSite!),
      subject: drift.Value(subject),
      remark: drift.Value(complaint),
      cOn: drift.Value(formattedDateTime),
    );

    await addComplaintVM.insertComplaint(complaintData);

    // ✅ Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Complaint submitted successfully.")),
    );

    // ✅ Navigate to the next page after a short delay (optional)
    await Future.delayed(Duration(milliseconds: 500)); // optional

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintHistoryPage(),
      ), // replace with your actual page
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(pageName: 'Add Complaints', isFilter: false),
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerticalSpace(),
            const Text(
              'Choose Site Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.colorPrimary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedSite,
                  hint: const Text('Select a site'),
                  items:
                      siteNames.map((site) {
                        return DropdownMenuItem(value: site, child: Text(site));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSite = value;
                    });
                  },
                ),
              ),
            ),
            VerticalSpace(),
            const Text(
              'Subject',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
            ),
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                hintText: "Enter Subject",
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.colorPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.colorPrimary),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
              maxLength: 25,
            ),
            VerticalSpace(),
            const Text(
              'Complaint',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
            ),
            TextField(
              controller: complaintController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: "Type Here....",
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.colorPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.colorPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.colorPrimary),
                ),
              ),
            ),
            VerticalSpace(),
            const Text(
              'Add Images',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
            ),
            ...List.generate(3, (index) {
              return Visibility(
                visible: index == 0 || uploadedImages[index] != null,
                child: Container(
                  margin: EdgeInsets.only(top: index == 0 ? 0 : 10),
                  padding: const EdgeInsets.all(8),
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.colorPrimary),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child:
                      uploadedImages[index] == null
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Capture Image ${index + 1}",
                                  style: TextStyle(fontSize: 10),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Upload Image",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.colorPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Image(image: uploadedImages[index]!),
                ),
              );
            }),
            VerticalSpace(),
            CustomButton(
              buttonText: 'SUBMIT',
              onPressed: () {
                _addComplaint();
              },
            ),
          ],
        ),
      ),
    );
  }
}
