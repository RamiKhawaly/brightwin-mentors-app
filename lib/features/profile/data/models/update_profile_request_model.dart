class UpdateProfileRequestModel {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? workEmail;
  final String? bio;
  final String? location;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final String? imageUrl;
  final String? currentJobTitle;
  final int? yearsOfExperience;
  final bool? profileVisible;

  UpdateProfileRequestModel({
    this.firstName,
    this.lastName,
    this.phone,
    this.workEmail,
    this.bio,
    this.location,
    this.linkedInUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.imageUrl,
    this.currentJobTitle,
    this.yearsOfExperience,
    this.profileVisible,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (workEmail != null) data['workEmail'] = workEmail;
    if (bio != null) data['bio'] = bio;
    if (location != null) data['location'] = location;
    if (linkedInUrl != null) data['linkedInUrl'] = linkedInUrl;
    if (githubUrl != null) data['githubUrl'] = githubUrl;
    if (portfolioUrl != null) data['portfolioUrl'] = portfolioUrl;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (currentJobTitle != null) data['currentJobTitle'] = currentJobTitle;
    if (yearsOfExperience != null) data['yearsOfExperience'] = yearsOfExperience;
    if (profileVisible != null) data['profileVisible'] = profileVisible;

    return data;
  }
}
