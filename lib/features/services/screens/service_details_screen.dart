import 'package:flutter/material.dart';

import '../../../shared/widgets/app_primary_button.dart';
import '../data/mock_service_data.dart';
import '../data/service_directory.dart';
import '../widgets/service_details_panel.dart';
import 'create_service_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceDirectory directory;
  final int serviceId;

  const ServiceDetailsScreen({
    super.key,
    required this.directory,
    required this.serviceId,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Widget _editButton(double maxWidth) {
    final button = AppPrimaryButton(
      text: 'Edit Service',
      icon: Icons.edit_outlined,
      width: maxWidth < 520 ? double.infinity : 280,
      onPressed: _edit,
    );
    if (maxWidth < 520) return button;
    return Align(alignment: Alignment.centerRight, child: button);
  }

  Future<void> _edit() async {
    final service = widget.directory.findById(widget.serviceId);
    if (service == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateServiceScreen(directory: widget.directory, service: service),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.directory.findById(widget.serviceId);
    if (service == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Service Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: Text('This service is no longer available.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Service Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 520 ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Service Details',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ServiceDetailsPanel(
                      service: service,
                      branchName: branchNameForService(service.branchId),
                    ),
                    const SizedBox(height: 20),
                    _editButton(constraints.maxWidth),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
