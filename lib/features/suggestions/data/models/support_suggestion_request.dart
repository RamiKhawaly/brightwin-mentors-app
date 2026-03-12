class SupportSuggestionRequest {
  final String title;
  final String description;

  SupportSuggestionRequest({
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}
