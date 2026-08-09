import 'package:flutter/material.dart';

class ExportButtons extends StatelessWidget {
  final void Function()? onExportCsv;
  final void Function()? onExportPdf;
  const ExportButtons({Key? key, this.onExportCsv, this.onExportPdf}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: onExportCsv,
          child: const Text('Export CSV'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onExportPdf,
          child: const Text('Export PDF'),
        ),
      ],
    );
  }
}
