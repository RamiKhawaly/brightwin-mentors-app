import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/session.dart';

class TimeSlotModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String? proposedBy;
  final bool isSelected;

  TimeSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.proposedBy,
    this.isSelected = false,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id']?.toString() ?? '',
      startTime: parseServerDateTime(json['startTime']),
      endTime: parseServerDateTime(json['endTime']),
      proposedBy: json['proposedBy']?.toString(),
      isSelected: json['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      if (proposedBy != null) 'proposedBy': proposedBy,
      'isSelected': isSelected,
    };
  }

  TimeSlot toEntity() {
    return TimeSlot(
      id: id,
      startTime: startTime,
      endTime: endTime,
      proposedBy: proposedBy,
      isSelected: isSelected,
    );
  }
}
