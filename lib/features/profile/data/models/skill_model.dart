enum SkillLevel {
  BEGINNER,
  INTERMEDIATE,
  ADVANCED,
  EXPERT;

  String get displayName {
    switch (this) {
      case SkillLevel.BEGINNER:
        return 'Beginner';
      case SkillLevel.INTERMEDIATE:
        return 'Intermediate';
      case SkillLevel.ADVANCED:
        return 'Advanced';
      case SkillLevel.EXPERT:
        return 'Expert';
    }
  }
}

class SkillModel {
  final int id;
  final String name;
  final String? category;
  final String? description;
  final bool? verified;
  final int? popularityCount;

  SkillModel({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.verified,
    this.popularityCount,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      verified: json['verified'] as bool?,
      popularityCount: json['popularityCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (verified != null) 'verified': verified,
      if (popularityCount != null) 'popularityCount': popularityCount,
    };
  }
}

class UserSkillModel {
  final int? id;
  final SkillModel skill;
  final SkillLevel? level;
  final int? yearsOfExperience;
  final bool isPrimary;
  final bool? extractedFromCV;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSkillModel({
    this.id,
    required this.skill,
    this.level,
    this.yearsOfExperience,
    this.isPrimary = false,
    this.extractedFromCV,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSkillModel.fromJson(Map<String, dynamic> json) {
    return UserSkillModel(
      id: json['id'] as int?,
      skill: SkillModel.fromJson(json['skill'] as Map<String, dynamic>),
      level: json['level'] != null
          ? SkillLevel.values.firstWhere(
              (e) => e.name == json['level'],
              orElse: () => SkillLevel.INTERMEDIATE,
            )
          : null,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      extractedFromCV: json['extractedFromCV'] as bool?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'skill': skill.toJson(),
      if (level != null) 'level': level!.name,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      'isPrimary': isPrimary,
      if (extractedFromCV != null) 'extractedFromCV': extractedFromCV,
      if (notes != null) 'notes': notes,
    };
  }
}
