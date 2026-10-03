import 'package:flutter/material.dart';

import '../data/mock_scheduling_data.dart';
import '../models/scheduling_models.dart';
import 'appointment_schedule_card.dart';
import 'availability_slot.dart';
import 'staff_schedule_row.dart';

const double scheduleRowHeight = 116;
const double scheduleHeaderHeight = 40;
const double scheduleSlotWidth = 108;

class TimeSlotGrid extends StatefulWidget {
  final List<SchedulingStaff> staff;
  final List<SchedulingBlock> blocks;
  final bool Function(SchedulingBlock block) isDimmed;
  final ValueChanged<SchedulingBlock> onAppointmentTap;
  final void Function(SchedulingStaff staff, int startMinute) onAvailableTap;

  const TimeSlotGrid({
    super.key,
    required this.staff,
    required this.blocks,
    required this.isDimmed,
    required this.onAppointmentTap,
    required this.onAvailableTap,
  });

  @override
  State<TimeSlotGrid> createState() => _TimeSlotGridState();
}

class _TimeSlotGridState extends State<TimeSlotGrid> {
  final ScrollController _staffVertical = ScrollController();
  final ScrollController _bodyVertical = ScrollController();
  final ScrollController _headerHorizontal = ScrollController();
  final ScrollController _bodyHorizontal = ScrollController();
  bool _lock = false;

  @override
  void initState() {
    super.initState();
    _link(_staffVertical, _bodyVertical);
    _link(_bodyVertical, _staffVertical);
    _link(_headerHorizontal, _bodyHorizontal);
    _link(_bodyHorizontal, _headerHorizontal);
  }

  void _link(ScrollController source, ScrollController target) {
    source.addListener(() {
      if (_lock || !source.hasClients || !target.hasClients) return;
      final max = target.position.maxScrollExtent;
      final next = source.offset.clamp(0.0, max);
      if ((target.offset - next).abs() < 1) return;
      _lock = true;
      target.jumpTo(next);
      _lock = false;
    });
  }

  @override
  void dispose() {
    _staffVertical.dispose();
    _bodyVertical.dispose();
    _headerHorizontal.dispose();
    _bodyHorizontal.dispose();
    super.dispose();
  }

  double get _timelineWidth => scheduleSlotCount * scheduleSlotWidth;

  @override
  Widget build(BuildContext context) {
    if (widget.staff.isEmpty) {
      return const Center(
        child: Text(
          'No staff match this filter',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final staffWidth = constraints.maxWidth < 720 ? 148.0 : 210.0;
        final hiddenScroll = ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: staffWidth,
              child: Column(
                children: [
                  _staffHeader(),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: hiddenScroll,
                      child: ListView.builder(
                        key: const Key('schedule-staff-list'),
                        controller: _staffVertical,
                        primary: false,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemExtent: scheduleRowHeight,
                        itemCount: widget.staff.length,
                        itemBuilder: (context, index) {
                          final staff = widget.staff[index];
                          final blocks = _blocksFor(staff.staffId);
                          return _lined(
                            StaffScheduleRow(
                              staff: staff,
                              summary: summarizeStaffDay(blocks),
                              height: scheduleRowHeight,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: scheduleHeaderHeight,
                    child: ScrollConfiguration(
                      behavior: hiddenScroll,
                      child: SingleChildScrollView(
                        controller: _headerHorizontal,
                        scrollDirection: Axis.horizontal,
                        primary: false,
                        child: _timeHeader(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _bodyHorizontal,
                      thumbVisibility: true,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      notificationPredicate: (notification) {
                        return notification.metrics.axis == Axis.horizontal;
                      },
                      child: SingleChildScrollView(
                        controller: _bodyHorizontal,
                        scrollDirection: Axis.horizontal,
                        primary: false,
                        child: SizedBox(
                          width: _timelineWidth,
                          child: ScrollConfiguration(
                            behavior: hiddenScroll,
                            child: ListView.builder(
                              controller: _bodyVertical,
                              primary: false,
                              padding: const EdgeInsets.only(bottom: 16),
                              itemExtent: scheduleRowHeight,
                              itemCount: widget.staff.length,
                              itemBuilder: (context, index) {
                                return _lined(
                                  _timelineRow(widget.staff[index]),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _staffHeader() {
    return Container(
      height: scheduleHeaderHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        color: Color(0xFFF7F8FC),
      ),
      child: const Text(
        'Staff',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _timeHeader() {
    return Container(
      width: _timelineWidth,
      height: scheduleHeaderHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        color: Color(0xFFF7F8FC),
      ),
      child: Row(
        children: [
          for (
            var minute = scheduleDayStartMinute;
            minute < scheduleDayEndMinute;
            minute += scheduleSlotMinutes
          )
            SizedBox(
              width: scheduleSlotWidth,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatScheduleTime(minute),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _lined(Widget child) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: child,
    );
  }

  List<SchedulingBlock> _blocksFor(String staffId) {
    return widget.blocks.where((block) => block.staffId == staffId).toList();
  }

  Widget _timelineRow(SchedulingStaff staff) {
    final blocks = _blocksFor(staff.staffId);
    final ordered = [
      ...blocks.where((block) => !block.conflict),
      ...blocks.where((block) => block.conflict),
    ];

    return SizedBox(
      height: scheduleRowHeight,
      width: _timelineWidth,
      child: Stack(
        children: [
          Row(
            children: [
              for (
                var minute = scheduleDayStartMinute;
                minute < scheduleDayEndMinute;
                minute += scheduleSlotMinutes
              )
                SizedBox(
                  width: scheduleSlotWidth,
                  height: scheduleRowHeight,
                  child: _slot(staff, blocks, minute),
                ),
            ],
          ),
          for (final block in ordered)
            Positioned(
              left: _offset(block.startMinute),
              width: _span(block.startMinute, block.endMinute),
              top: 0,
              bottom: 0,
              child: block.kind == ScheduleBlockKind.booked
                  ? Tooltip(
                      message: '${block.title}, ${block.subtitle}',
                      child: AppointmentScheduleCard(
                        block: block,
                        dimmed: widget.isDimmed(block),
                        onTap: () => widget.onAppointmentTap(block),
                      ),
                    )
                  : _ClosureBlock(block: block),
            ),
        ],
      ),
    );
  }

  Widget _slot(
    SchedulingStaff staff,
    List<SchedulingBlock> blocks,
    int minute,
  ) {
    final covered = blocks.any((block) => block.coversMinute(minute));
    if (covered) return const SizedBox.shrink();
    return AvailabilitySlot(
      tooltip: 'Open ${formatScheduleTime(minute)} for ${staff.name}',
      onTap: () => widget.onAvailableTap(staff, minute),
    );
  }

  double _offset(int minute) {
    return (minute - scheduleDayStartMinute) /
        scheduleSlotMinutes *
        scheduleSlotWidth;
  }

  double _span(int start, int end) => _offset(end) - _offset(start);
}

class _ClosureBlock extends StatelessWidget {
  final SchedulingBlock block;

  const _ClosureBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final (
      Color foreground,
      Color background,
      Color border,
      IconData icon,
    ) = switch (block.kind) {
      ScheduleBlockKind.onBreak => (
        const Color(0xFFF9A825),
        const Color(0xFFFFF8E1),
        const Color(0xFFFFE082),
        Icons.free_breakfast_outlined,
      ),
      ScheduleBlockKind.leave => (
        const Color(0xFFC62828),
        const Color(0xFFFFF4F4),
        const Color(0xFFFFCDD2),
        Icons.event_busy_outlined,
      ),
      ScheduleBlockKind.offDuty => (
        const Color(0xFF757575),
        const Color(0xFFF7F7F7),
        const Color(0xFFE0E0E0),
        Icons.do_not_disturb_on_outlined,
      ),
      ScheduleBlockKind.booked => (
        const Color(0xFF673AB7),
        const Color(0xFFF6F3FB),
        const Color(0xFFD1C4E9),
        Icons.event_note_outlined,
      ),
    };

    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  block.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
