import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/appointment_service_line.dart';
import '../models/appointment_status.dart';
import '../models/salon_lookups.dart';

const List<BranchLookup> mockBranches = [
  BranchLookup(
    branchId: 1,
    branchCode: 'BR-001',
    branchName: 'Colombo',
  ),
  BranchLookup(
    branchId: 2,
    branchCode: 'BR-002',
    branchName: 'Kandy',
  ),
];

const List<CustomerLookup> mockCustomers = [
  CustomerLookup(
    customerId: 1,
    customerCode: 'CUS-001',
    firstName: 'Amanda',
    lastName: 'Silva',
    mobileNo: '0771234567',
    branchId: 1,
  ),
  CustomerLookup(
    customerId: 2,
    customerCode: 'CUS-002',
    firstName: 'Sarah',
    lastName: 'Perera',
    mobileNo: '0712345678',
    branchId: 1,
  ),
  CustomerLookup(
    customerId: 3,
    customerCode: 'CUS-003',
    firstName: 'Emma',
    lastName: 'Fernando',
    mobileNo: '0751234567',
    branchId: 1,
  ),
  CustomerLookup(
    customerId: 4,
    customerCode: 'CUS-004',
    firstName: 'Daniel',
    lastName: 'Silva',
    mobileNo: '0724567890',
    branchId: 2,
  ),
  CustomerLookup(
    customerId: 5,
    customerCode: 'CUS-005',
    firstName: 'Nethmi',
    lastName: 'Perera',
    mobileNo: '0763456789',
    branchId: 2,
  ),
];

const List<EmployeeLookup> mockEmployees = [
  EmployeeLookup(
    employeeId: 1,
    employeeCode: 'EMP-001',
    firstName: 'Kevin',
    lastName: 'Perera',
    designation: 'Stylist',
    branchId: 1,
  ),
  EmployeeLookup(
    employeeId: 2,
    employeeCode: 'EMP-002',
    firstName: 'Emily',
    lastName: 'Fernando',
    designation: 'Colour Specialist',
    branchId: 1,
  ),
  EmployeeLookup(
    employeeId: 3,
    employeeCode: 'EMP-003',
    firstName: 'Sophia',
    lastName: 'Silva',
    designation: 'Therapist',
    branchId: 2,
  ),
];

const List<ServiceLookup> mockServices = [
  ServiceLookup(
    serviceId: 1,
    serviceCode: 'SRV-001',
    serviceName: 'Hair Cut',
    durationMinutes: 45,
    price: 2500,
    branchId: 1,
  ),
  ServiceLookup(
    serviceId: 2,
    serviceCode: 'SRV-002',
    serviceName: 'Hair Colour',
    durationMinutes: 90,
    price: 7500,
    branchId: 1,
  ),
  ServiceLookup(
    serviceId: 3,
    serviceCode: 'SRV-003',
    serviceName: 'Facial',
    durationMinutes: 60,
    price: 4500,
    branchId: 1,
  ),
  ServiceLookup(
    serviceId: 4,
    serviceCode: 'SRV-004',
    serviceName: 'Hair Spa',
    durationMinutes: 75,
    price: 5500,
    branchId: 1,
  ),
  ServiceLookup(
    serviceId: 5,
    serviceCode: 'SRV-005',
    serviceName: 'Hair Cut',
    durationMinutes: 45,
    price: 2200,
    branchId: 2,
  ),
  ServiceLookup(
    serviceId: 6,
    serviceCode: 'SRV-006',
    serviceName: 'Bridal Makeup',
    durationMinutes: 120,
    price: 15000,
    branchId: 2,
  ),
];

final List<Appointment> mockAppointments = [
  Appointment(
    appointmentId: 1,
    branchId: 1,
    customerId: 1,
    appointmentDate: DateTime(2026, 9, 30),
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 9, minute: 45),
    employeeId: 1,
    status: AppointmentStatus.scheduled,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 1,
        appointmentId: 1,
        serviceId: 1,
      ),
    ],
  ),
  Appointment(
    appointmentId: 2,
    branchId: 1,
    customerId: 2,
    appointmentDate: DateTime(2026, 9, 30),
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 12, minute: 0),
    employeeId: 2,
    status: AppointmentStatus.confirmed,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 2,
        appointmentId: 2,
        serviceId: 2,
      ),
      AppointmentServiceLine(
        appointmentServiceId: 3,
        appointmentId: 2,
        serviceId: 4,
      ),
    ],
  ),
  Appointment(
    appointmentId: 3,
    branchId: 1,
    customerId: 3,
    appointmentDate: DateTime(2026, 9, 30),
    startTime: const TimeOfDay(hour: 13, minute: 0),
    endTime: const TimeOfDay(hour: 14, minute: 0),
    employeeId: 1,
    status: AppointmentStatus.completed,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 4,
        appointmentId: 3,
        serviceId: 3,
      ),
    ],
  ),
  Appointment(
    appointmentId: 4,
    branchId: 1,
    customerId: 1,
    appointmentDate: DateTime(2026, 10, 1),
    startTime: const TimeOfDay(hour: 11, minute: 0),
    endTime: const TimeOfDay(hour: 12, minute: 30),
    employeeId: 2,
    status: AppointmentStatus.scheduled,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 5,
        appointmentId: 4,
        serviceId: 4,
      ),
    ],
  ),
  Appointment(
    appointmentId: 5,
    branchId: 2,
    customerId: 4,
    appointmentDate: DateTime(2026, 10, 1),
    startTime: const TimeOfDay(hour: 9, minute: 30),
    endTime: const TimeOfDay(hour: 11, minute: 30),
    employeeId: 3,
    status: AppointmentStatus.confirmed,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 6,
        appointmentId: 5,
        serviceId: 6,
      ),
      AppointmentServiceLine(
        appointmentServiceId: 7,
        appointmentId: 5,
        serviceId: 5,
      ),
    ],
  ),
  Appointment(
    appointmentId: 6,
    branchId: 2,
    customerId: 5,
    appointmentDate: DateTime(2026, 9, 29),
    startTime: const TimeOfDay(hour: 15, minute: 0),
    endTime: const TimeOfDay(hour: 15, minute: 45),
    employeeId: 3,
    status: AppointmentStatus.cancelled,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 8,
        appointmentId: 6,
        serviceId: 5,
      ),
    ],
  ),
  Appointment(
    appointmentId: 7,
    branchId: 1,
    customerId: 2,
    appointmentDate: DateTime(2026, 10, 2),
    startTime: const TimeOfDay(hour: 16, minute: 0),
    endTime: const TimeOfDay(hour: 16, minute: 45),
    employeeId: 1,
    status: AppointmentStatus.scheduled,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 9,
        appointmentId: 7,
        serviceId: 1,
      ),
    ],
  ),
  Appointment(
    appointmentId: 8,
    branchId: 2,
    customerId: 4,
    appointmentDate: DateTime(2026, 9, 30),
    startTime: const TimeOfDay(hour: 14, minute: 0),
    endTime: const TimeOfDay(hour: 16, minute: 0),
    employeeId: 3,
    status: AppointmentStatus.completed,
    appointmentServices: const [
      AppointmentServiceLine(
        appointmentServiceId: 10,
        appointmentId: 8,
        serviceId: 6,
      ),
    ],
  ),
];
