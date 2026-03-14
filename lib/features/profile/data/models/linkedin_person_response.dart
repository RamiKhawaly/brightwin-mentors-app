class LinkedInCurrentCompany {
  final String company;
  final String title;
  final String? companyUrl;
  final String? startDate;
  final String? location;

  LinkedInCurrentCompany({
    required this.company,
    required this.title,
    this.companyUrl,
    this.startDate,
    this.location,
  });

  factory LinkedInCurrentCompany.fromJson(Map<String, dynamic> json) {
    return LinkedInCurrentCompany(
      company: (json['company'] ?? json['company_name'] ?? json['name'] ?? '').toString(),
      title: (json['title'] ?? json['position'] ?? json['job_title'] ?? '').toString(),
      companyUrl: (json['companyUrl'] ?? json['company_url'] ??
          json['company_linkedin_url'] ?? json['linkedInUrl'] ??
          json['link']) as String?,
      startDate: _parseDate(json['startDate'] ?? json['start_date'] ??
          json['date']?['start'] ?? json['starts_at']),
      location: (json['location']) as String?,
    );
  }

  /// Converts various date shapes to a "YYYY-MM" string.
  static String? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) {
      final y = raw['year'] as int?;
      final m = raw['month'] as int?;
      if (y != null) {
        return m != null
            ? '$y-${m.toString().padLeft(2, '0')}'
            : '$y';
      }
    }
    return null;
  }
}

class LinkedInExperienceItem {
  final String company;
  final String title;
  final String? companyUrl;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? location;
  final String? description;

  LinkedInExperienceItem({
    required this.company,
    required this.title,
    this.companyUrl,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.location,
    this.description,
  });

  factory LinkedInExperienceItem.fromJson(Map<String, dynamic> json) {
    final rawEnd = json['endDate'] ?? json['end_date'] ?? json['ends_at'];
    final isCurrent = (json['isCurrent'] as bool?) ??
        (json['is_current'] as bool?) ??
        (json['currently_working'] as bool?) ??
        rawEnd == null;

    return LinkedInExperienceItem(
      company: (json['company'] ?? json['company_name'] ?? json['organization'] ?? '').toString(),
      title: (json['title'] ?? json['position'] ?? json['job_title'] ?? '').toString(),
      companyUrl: (json['companyUrl'] ?? json['company_url'] ??
          json['company_linkedin_url']) as String?,
      startDate: _parseDate(json['startDate'] ?? json['start_date'] ?? json['starts_at']),
      endDate: _parseDate(rawEnd),
      isCurrent: isCurrent,
      location: (json['location']) as String?,
      description: (json['description'] ?? json['summary']) as String?,
    );
  }

  /// Parses "YYYY-MM", "YYYY-MM-DD", or {year, month} map into a "YYYY-MM" string.
  static String? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map) {
      final y = raw['year'] as int?;
      final m = raw['month'] as int?;
      if (y != null) {
        return m != null
            ? '$y-${m.toString().padLeft(2, '0')}'
            : '$y';
      }
    }
    return null;
  }

  /// Parses a date string into DateTime (used for saving to backend).
  static DateTime? parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {}
    try {
      final parts = raw.split('-');
      if (parts.length >= 2) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }
      if (parts.length == 1) {
        return DateTime(int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }
}

class LinkedInPersonResponse {
  final String? url;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? headline;
  final String? location;
  final String? summary;
  final String? imgUrl;
  final int? followers;
  final int? connections;
  final LinkedInCurrentCompany? currentCompany;
  final List<LinkedInExperienceItem> experience;

  LinkedInPersonResponse({
    this.url,
    this.name,
    this.firstName,
    this.lastName,
    this.headline,
    this.location,
    this.summary,
    this.imgUrl,
    this.followers,
    this.connections,
    this.currentCompany,
    this.experience = const [],
  });

  factory LinkedInPersonResponse.fromJson(Map<String, dynamic> json) {
    // ── URL ──────────────────────────────────────────────────────────────────
    final url = (json['url'] ?? json['linkedin_url'] ??
        json['public_profile_url'] ?? json['profile_url']) as String?;

    // ── Name ─────────────────────────────────────────────────────────────────
    final name = (json['name'] ?? json['full_name']) as String?;
    final firstName = (json['firstName'] ?? json['first_name']) as String?;
    final lastName = (json['lastName'] ?? json['last_name']) as String?;

    // ── Profile fields ───────────────────────────────────────────────────────
    final headline = (json['headline'] ?? json['subtitle'] ?? json['job_title']) as String?;
    final location = (json['location'] ?? json['city']) as String?;
    final summary = (json['summary'] ?? json['about'] ??
        json['description'] ?? json['bio']) as String?;
    final imgUrl = (json['imgUrl'] ?? json['img_url'] ?? json['avatar'] ??
        json['picture'] ?? json['profile_pic_url'] ?? json['photo_url'] ??
        json['profile_picture']) as String?;

    // ── Counts ───────────────────────────────────────────────────────────────
    final followers = (json['followers'] ?? json['follower_count'] ??
        json['followers_count']) as int?;
    final connections = (json['connections'] ?? json['connections_count'] ??
        json['connection_count']) as int?;

    // ── Current company ──────────────────────────────────────────────────────
    LinkedInCurrentCompany? currentCompany;
    final ccRaw = json['currentCompany'] ?? json['current_company'];
    if (ccRaw is Map<String, dynamic>) {
      currentCompany = LinkedInCurrentCompany.fromJson(ccRaw);
    }

    // ── Experience ───────────────────────────────────────────────────────────
    final expRaw = json['experience'] ?? json['experiences'] ??
        json['work_experience'] ?? json['positions'];
    final experience = (expRaw as List<dynamic>?)
            ?.map((e) =>
                LinkedInExperienceItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // ── Derive currentCompany from experience if not explicitly provided ─────
    if (currentCompany == null && experience.isNotEmpty) {
      final current = experience.firstWhere(
        (e) => e.isCurrent,
        orElse: () => experience.first,
      );
      currentCompany = LinkedInCurrentCompany(
        company: current.company,
        title: current.title,
        companyUrl: current.companyUrl,
        startDate: current.startDate,
        location: current.location,
      );
    }

    return LinkedInPersonResponse(
      url: url,
      name: name,
      firstName: firstName,
      lastName: lastName,
      headline: headline,
      location: location,
      summary: summary,
      imgUrl: imgUrl,
      followers: followers,
      connections: connections,
      currentCompany: currentCompany,
      experience: experience,
    );
  }

  String get displayName =>
      name ??
      [firstName, lastName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
}
