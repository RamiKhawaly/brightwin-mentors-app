class RescheduleRequest {
  final String reason;
  final List<TimeSlotProposal>? newTimeSlots;

  RescheduleRequest({
    required this.reason,
    this.newTimeSlots,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      if (newTimeSlots != null)
        'newTimeSlots': newTimeSlots!.map((slot) => slot.toJson()).toList(),
    };
  }
}

class TimeSlotProposal {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlotProposal({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}
