enum SuggestionStatus {
  NEW,
  REVIEWING,
  PLANNED,
  IN_PROGRESS,
  COMPLETED,
  REJECTED,
  CLOSED,
}

extension SuggestionStatusExtension on SuggestionStatus {
  String get displayName {
    switch (this) {
      case SuggestionStatus.NEW:
        return 'New';
      case SuggestionStatus.REVIEWING:
        return 'Under Review';
      case SuggestionStatus.PLANNED:
        return 'Planned';
      case SuggestionStatus.IN_PROGRESS:
        return 'In Progress';
      case SuggestionStatus.COMPLETED:
        return 'Completed';
      case SuggestionStatus.REJECTED:
        return 'Rejected';
      case SuggestionStatus.CLOSED:
        return 'Closed';
    }
  }

  String get apiValue {
    return toString().split('.').last;
  }

  static SuggestionStatus fromString(String value) {
    return SuggestionStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => SuggestionStatus.NEW,
    );
  }
}
