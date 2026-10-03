import '../models/scheduling_models.dart';

/// Demo day used by Today on the scheduling board.
final DateTime schedulingDemoDate = DateTime(2026, 10, 10);

const List<SchedulingStaff> schedulingStaff = [
  SchedulingStaff(staffId: 'kasun', name: 'Kasun Perera', role: 'Hair Stylist'),
  SchedulingStaff(
    staffId: 'amali',
    name: 'Amali Fernando',
    role: 'Colour Specialist',
  ),
  SchedulingStaff(staffId: 'ravi', name: 'Ravi Silva', role: 'Senior Stylist'),
  SchedulingStaff(
    staffId: 'nadeesha',
    name: 'Nadeesha Perera',
    role: 'Beautician',
  ),
  SchedulingStaff(staffId: 'dilshan', name: 'Dilshan Wickrama', role: 'Barber'),
  SchedulingStaff(
    staffId: 'ishara',
    name: 'Ishara Jayawardena',
    role: 'Hair Therapist',
  ),
];

final List<SchedulingAppointment> mockSchedulingAppointments = [
  ..._demoDayAppointments(),
  ..._previousDayAppointments(),
  ..._nextDayAppointments(),
];

final List<AvailabilitySuggestion> mockAvailabilitySuggestions = [
  AvailabilitySuggestion(
    customerName: 'Nimal Perera',
    services: const [
      SuggestedService(name: 'Haircut', durationMinutes: 30),
      SuggestedService(name: 'Hair Coloring', durationMinutes: 60),
      SuggestedService(name: 'Hair Wash', durationMinutes: 30),
    ],
    options: [
      SuggestedSchedule(
        windowLabel: formatScheduleRange(10 * 60, 12 * 60),
        assignments: const [
          SuggestedAssignment(
            serviceName: 'Haircut',
            staffName: 'Kasun Perera',
            startMinute: 10 * 60,
            endMinute: 10 * 60 + 30,
          ),
          SuggestedAssignment(
            serviceName: 'Hair Coloring',
            staffName: 'Amali Fernando',
            startMinute: 10 * 60 + 30,
            endMinute: 11 * 60 + 30,
          ),
          SuggestedAssignment(
            serviceName: 'Hair Wash',
            staffName: 'Kasun Perera',
            startMinute: 11 * 60 + 30,
            endMinute: 12 * 60,
          ),
        ],
      ),
      SuggestedSchedule(
        windowLabel: formatScheduleRange(11 * 60, 13 * 60),
        assignments: const [
          SuggestedAssignment(
            serviceName: 'Haircut',
            staffName: 'Ravi Silva',
            startMinute: 11 * 60,
            endMinute: 11 * 60 + 30,
          ),
          SuggestedAssignment(
            serviceName: 'Hair Coloring',
            staffName: 'Amali Fernando',
            startMinute: 11 * 60 + 30,
            endMinute: 12 * 60 + 30,
          ),
          SuggestedAssignment(
            serviceName: 'Hair Wash',
            staffName: 'Kasun Perera',
            startMinute: 12 * 60 + 30,
            endMinute: 13 * 60,
          ),
        ],
      ),
    ],
  ),
  AvailabilitySuggestion(
    customerName: 'Hiruni Senanayake',
    services: const [
      SuggestedService(name: 'Facial', durationMinutes: 60),
      SuggestedService(name: 'Hair Wash', durationMinutes: 30),
    ],
    options: [
      SuggestedSchedule(
        windowLabel: formatScheduleRange(13 * 60 + 30, 15 * 60),
        assignments: const [
          SuggestedAssignment(
            serviceName: 'Facial',
            staffName: 'Nadeesha Perera',
            startMinute: 13 * 60 + 30,
            endMinute: 14 * 60 + 30,
          ),
          SuggestedAssignment(
            serviceName: 'Hair Wash',
            staffName: 'Amali Fernando',
            startMinute: 14 * 60 + 30,
            endMinute: 15 * 60,
          ),
        ],
      ),
      SuggestedSchedule(
        windowLabel: formatScheduleRange(9 * 60, 10 * 60 + 30),
        assignments: const [
          SuggestedAssignment(
            serviceName: 'Facial',
            staffName: 'Nadeesha Perera',
            startMinute: 9 * 60,
            endMinute: 10 * 60,
          ),
          SuggestedAssignment(
            serviceName: 'Hair Wash',
            staffName: 'Dilshan Wickrama',
            startMinute: 10 * 60 + 30,
            endMinute: 11 * 60,
          ),
        ],
      ),
    ],
  ),
];

List<SchedulingAppointment> _demoDayAppointments() {
  final date = schedulingDemoDate;
  return [
    SchedulingAppointment(
      reference: 'APT-1042',
      customerName: 'Nimal Perera',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 30,
          staffId: 'kasun',
          startMinute: 10 * 60,
          endMinute: 10 * 60 + 30,
        ),
        SchedulingServiceSegment(
          serviceName: 'Hair Coloring',
          durationMinutes: 60,
          staffId: 'amali',
          startMinute: 10 * 60 + 30,
          endMinute: 11 * 60 + 30,
        ),
        SchedulingServiceSegment(
          serviceName: 'Hair Wash',
          durationMinutes: 30,
          staffId: 'kasun',
          startMinute: 11 * 60 + 30,
          endMinute: 12 * 60,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1048',
      customerName: 'Tharushi Mendis',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Hair Coloring',
          durationMinutes: 60,
          staffId: 'amali',
          startMinute: 9 * 60,
          endMinute: 10 * 60,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1051',
      customerName: 'Dineth Fernando',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 60,
          staffId: 'ravi',
          startMinute: 9 * 60 + 30,
          endMinute: 10 * 60 + 30,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1055',
      customerName: 'Chamodi Silva',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Hair Spa',
          durationMinutes: 90,
          staffId: 'ravi',
          startMinute: 14 * 60 + 30,
          endMinute: 16 * 60,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1060',
      customerName: 'Madhavi Jayasuriya',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Facial',
          durationMinutes: 60,
          staffId: 'nadeesha',
          startMinute: 10 * 60,
          endMinute: 11 * 60,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1062',
      customerName: 'Ishani Costa',
      date: date,
      status: 'Scheduled',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Facial',
          durationMinutes: 60,
          staffId: 'nadeesha',
          startMinute: 11 * 60 + 30,
          endMinute: 12 * 60 + 30,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1070',
      customerName: 'Sanduni Rajapaksa',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Hair Spa',
          durationMinutes: 90,
          staffId: 'kasun',
          startMinute: 14 * 60,
          endMinute: 15 * 60 + 30,
          conflict: true,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1071',
      customerName: 'Thisara Gunasekara',
      date: date,
      status: 'Scheduled',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 30,
          staffId: 'kasun',
          startMinute: 15 * 60,
          endMinute: 15 * 60 + 30,
          conflict: true,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1080',
      customerName: 'Priya Fernando',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Hair Coloring',
          durationMinutes: 90,
          staffId: 'amali',
          startMinute: 15 * 60,
          endMinute: 16 * 60 + 30,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1088',
      customerName: 'Anuki Weerasinghe',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Bridal Makeup',
          durationMinutes: 120,
          staffId: 'nadeesha',
          startMinute: 15 * 60 + 30,
          endMinute: 17 * 60 + 30,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1090',
      customerName: 'Lakmal Perera',
      date: date,
      status: 'Completed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 30,
          staffId: 'dilshan',
          startMinute: 9 * 60,
          endMinute: 9 * 60 + 30,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1092',
      customerName: 'Sahan Dias',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 30,
          staffId: 'dilshan',
          startMinute: 10 * 60,
          endMinute: 10 * 60 + 30,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1096',
      customerName: 'Yeshan Alwis',
      date: date,
      status: 'Scheduled',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 30,
          staffId: 'kasun',
          startMinute: 17 * 60,
          endMinute: 17 * 60 + 30,
        ),
      ],
    ),
  ];
}

List<SchedulingAppointment> _previousDayAppointments() {
  final date = DateTime(2026, 10, 9);
  return [
    SchedulingAppointment(
      reference: 'APT-1030',
      customerName: 'Ruwan Perera',
      date: date,
      status: 'Completed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 60,
          staffId: 'kasun',
          startMinute: 10 * 60,
          endMinute: 11 * 60,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1033',
      customerName: 'Shamali Dias',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Hair Coloring',
          durationMinutes: 90,
          staffId: 'amali',
          startMinute: 11 * 60,
          endMinute: 12 * 60 + 30,
        ),
      ],
    ),
  ];
}

List<SchedulingAppointment> _nextDayAppointments() {
  final date = DateTime(2026, 10, 11);
  return [
    SchedulingAppointment(
      reference: 'APT-1102',
      customerName: 'Harini Silva',
      date: date,
      status: 'Scheduled',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Facial',
          durationMinutes: 60,
          staffId: 'nadeesha',
          startMinute: 10 * 60,
          endMinute: 11 * 60,
        ),
      ],
    ),
    SchedulingAppointment(
      reference: 'APT-1106',
      customerName: 'Malith Perera',
      date: date,
      status: 'Confirmed',
      services: const [
        SchedulingServiceSegment(
          serviceName: 'Haircut',
          durationMinutes: 30,
          staffId: 'ravi',
          startMinute: 9 * 60 + 30,
          endMinute: 10 * 60,
        ),
      ],
    ),
  ];
}

final List<SchedulingBlock> _fixedBlocks = [
  ..._demoDayClosures(),
  ..._lunchBreaks(DateTime(2026, 10, 9)),
  ..._lunchBreaks(DateTime(2026, 10, 11)),
];

List<SchedulingBlock> _demoDayClosures() {
  final date = schedulingDemoDate;
  return [
    _break(date, 'kasun', 13 * 60),
    _break(date, 'amali', 13 * 60),
    _break(date, 'ravi', 13 * 60),
    _break(date, 'nadeesha', 13 * 60),
    _break(date, 'dilshan', 11 * 60),
    SchedulingBlock(
      blockId: 'dilshan-off-$date',
      staffId: 'dilshan',
      date: date,
      kind: ScheduleBlockKind.offDuty,
      startMinute: 13 * 60,
      endMinute: scheduleDayEndMinute,
      title: 'Off duty',
      subtitle: 'From 13:00',
    ),
    SchedulingBlock(
      blockId: 'ishara-leave-$date',
      staffId: 'ishara',
      date: date,
      kind: ScheduleBlockKind.leave,
      startMinute: scheduleDayStartMinute,
      endMinute: scheduleDayEndMinute,
      title: 'On leave',
      subtitle: 'Not available today',
    ),
  ];
}

List<SchedulingBlock> _lunchBreaks(DateTime date) {
  return [
    for (final staff in schedulingStaff) _break(date, staff.staffId, 13 * 60),
  ];
}

SchedulingBlock _break(DateTime date, String staffId, int startMinute) {
  return SchedulingBlock(
    blockId: '$staffId-break-$date-$startMinute',
    staffId: staffId,
    date: date,
    kind: ScheduleBlockKind.onBreak,
    startMinute: startMinute,
    endMinute: startMinute + scheduleSlotMinutes,
    title: 'Break',
    subtitle: formatScheduleRange(
      startMinute,
      startMinute + scheduleSlotMinutes,
    ),
  );
}

List<SchedulingBlock> _defaultBreaks(DateTime date) => _lunchBreaks(date);

List<SchedulingBlock> blocksForDate(DateTime date) {
  final booked = [
    for (final appointment in appointmentsForDate(date))
      ...appointment.toBlocks(),
  ];
  final fixed = _fixedBlocks.where(
    (block) => isSameScheduleDay(block.date, date),
  );
  if (booked.isEmpty && fixed.isEmpty) return _defaultBreaks(date);
  return [...booked, ...fixed];
}

List<SchedulingAppointment> appointmentsForDate(DateTime date) {
  return mockSchedulingAppointments
      .where((item) => isSameScheduleDay(item.date, date))
      .toList();
}

SchedulingAppointment? appointmentByReference(String? reference) {
  if (reference == null) return null;
  for (final appointment in mockSchedulingAppointments) {
    if (appointment.reference == reference) return appointment;
  }
  return null;
}

SchedulingStaff staffById(String staffId) {
  return schedulingStaff.firstWhere((item) => item.staffId == staffId);
}

List<String> schedulingServiceNames() {
  final names = <String>{
    for (final appointment in mockSchedulingAppointments)
      for (final segment in appointment.services) segment.serviceName,
  };
  final sorted = names.toList()..sort();
  return sorted;
}

const List<String> schedulingStatuses = ['Confirmed', 'Scheduled', 'Completed'];

int openSlotCount(List<SchedulingBlock> blocks) {
  var count = 0;
  for (
    var minute = scheduleDayStartMinute;
    minute < scheduleDayEndMinute;
    minute += scheduleSlotMinutes
  ) {
    final covered = blocks.any((block) => block.coversMinute(minute));
    if (!covered) count++;
  }
  return count;
}

StaffDaySummary summarizeStaffDay(List<SchedulingBlock> blocks) {
  if (blocks.any((block) => block.kind == ScheduleBlockKind.leave)) {
    return const StaffDaySummary('On leave', StaffDayState.leave);
  }

  final offDuty = blocks.where(
    (block) => block.kind == ScheduleBlockKind.offDuty,
  );
  final open = openSlotCount(blocks);
  if (offDuty.isNotEmpty && open == 0) {
    return const StaffDaySummary('Off duty', StaffDayState.offDuty);
  }
  if (offDuty.isNotEmpty) {
    final start = offDuty.first.startMinute;
    return StaffDaySummary(
      'Off from ${formatScheduleTime(start)}',
      StaffDayState.offDuty,
    );
  }
  if (open == 0) {
    return const StaffDaySummary('Fully booked', StaffDayState.busy);
  }
  return StaffDaySummary('$open open', StaffDayState.open);
}

SchedulingBlock? firstConflict(List<SchedulingBlock> blocks) {
  for (final block in blocks) {
    if (block.conflict) return block;
  }
  return null;
}
