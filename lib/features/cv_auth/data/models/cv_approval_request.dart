class CVApprovalRequest {
  final String sessionId;
  final bool approved;
  final String? rejectionReason;

  CVApprovalRequest({
    required this.sessionId,
    required this.approved,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'approved': approved,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }
}
