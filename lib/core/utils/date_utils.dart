/// Parses a datetime string from the server, treating it as UTC if no
/// timezone info is present, then converts to the device's local timezone.
///
/// The backend uses [LocalDateTime] which serializes without timezone info
/// (e.g. "2025-03-10T14:30:00"). The database is configured with UTC, so
/// these values are always UTC. This function ensures correct local display.
DateTime parseServerDateTime(String dateStr) {
  final hasTimezone =
      dateStr.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(dateStr);
  final utcString = hasTimezone ? dateStr : '${dateStr}Z';
  return DateTime.parse(utcString).toLocal();
}

/// Same as [parseServerDateTime] but accepts null and returns null.
DateTime? parseServerDateTimeOrNull(String? dateStr) {
  if (dateStr == null) return null;
  return parseServerDateTime(dateStr);
}
