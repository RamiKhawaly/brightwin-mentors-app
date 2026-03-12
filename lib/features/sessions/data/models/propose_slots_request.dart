class ProposeSlotsRequest {
  final List<TimeSlotProposal> timeSlots;

  ProposeSlotsRequest({required this.timeSlots});

  Map<String, dynamic> toJson() {
    return {
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
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
