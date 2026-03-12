class JobImportRequest {
  final String url;

  JobImportRequest({required this.url});

  Map<String, dynamic> toJson() => {
        'url': url,
      };
}
