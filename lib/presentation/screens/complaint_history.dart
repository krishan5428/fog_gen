import 'package:flutter/material.dart';
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/screens/add_complaints.dart';

import '../widgets/app_bar.dart';
import '../widgets/complaint_item.dart';
import '../widgets/custom_button.dart';

class ComplaintHistoryPage extends StatefulWidget {
  final List? complaints;

  const ComplaintHistoryPage({super.key, this.complaints});

  @override
  State<ComplaintHistoryPage> createState() => _ComplaintHistoryPageState();
}

class _ComplaintHistoryPageState extends State<ComplaintHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(pageName: 'Complaint History', isFilter: false),
      body:
          widget.complaints!.isEmpty
              ? const Center(
                child: Text(
                  'No Complaint found',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: widget.complaints?.length,
                padding: EdgeInsets.only(bottom: 10),
                itemBuilder: (context, index) {
                  return ComplaintItem();
                },
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: CustomButton(
          buttonText: 'RAISE A COMPLAINT',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddComplaintPage()),
            );
          },
          backgroundColor: AppColors.colorPrimary,
          foregroundColor: AppColors.litePrimary,
        ),
      ),
    );
  }
}
