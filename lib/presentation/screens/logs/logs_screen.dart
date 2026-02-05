import 'package:flutter/material.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../dialog/confirmation_dialog.dart';
import '../../../core/repo/logs_service.dart';
import '../../widgets/app_bar.dart';
import 'log_entry.dart';
import 'logs_viewmodel.dart';

class LogsScreen extends StatelessWidget {
  final PanelData panelData;

  const LogsScreen({
    super.key,
    required this.panelData,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LogsViewModel(
        logsService: LogsService(),
        panelData: panelData,
      ),
      child: const _LogsView(),
    );
  }
}

class _LogsView extends StatelessWidget {
  const _LogsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        pageName: "Panel Logs",
        isFilter: false,
        isDash: false,
        isProfile: false,
        onBack: () => Navigator.pop(context),
        extraActions: [
          Consumer<LogsViewModel>(
            builder: (context, vm, child) {
              if (vm.state == LogsState.success && vm.logs.isNotEmpty) {
                return TextButton(
                  onPressed: () => _showExportDialog(context, vm),
                  child: const Text(
                    "Export Log",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<LogsViewModel>(
        builder: (context, vm, _) {
          switch (vm.state) {
            case LogsState.loading:
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.colorPrimary));
            case LogsState.error:
              return _errorState(vm);
            case LogsState.empty:
              return const Center(child: Text("No logs found"));
            case LogsState.success:
              return _tableState(vm.logs);
          }
        },
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context, LogsViewModel vm) async {
    final bool? confirm = await showConfirmationDialog(
      context: context,
      title: "Save PDF",
      message:
          "This will save the logs to 'fogshield/logs' in your phone storage.",
      confirmText: "Save",
      cancelText: "Cancel",
    );

    if (confirm == true) {
      vm.exportPdf(context);
    }
  }

  Widget _errorState(LogsViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.red),
          const Text("Failed to fetch logs"),
          ElevatedButton(onPressed: vm.fetchLogs, child: const Text("Retry"))
        ],
      ),
    );
  }

  // UPDATED LOGS SCREEN AS A THREE-COLUMN TABLE
  Widget _tableState(List<LogEntry> logs) {
    final timeFormat = DateFormat("hh:mm:ss a");
    final dateFormat = DateFormat("MMM dd, yyyy");

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columnSpacing: 12,
          horizontalMargin: 10,
          columns: const [
            DataColumn(
                label: Text('Alert Name',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Time',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Date',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: logs.map((log) {
            return DataRow(cells: [
              DataCell(
                SizedBox(
                  width: 120, // Constrain width for long alert names
                  child: Text(
                    log.message,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
              DataCell(Text(timeFormat.format(log.timestamp),
                  style: const TextStyle(fontSize: 11))),
              DataCell(Text(dateFormat.format(log.timestamp),
                  style: const TextStyle(fontSize: 11))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
