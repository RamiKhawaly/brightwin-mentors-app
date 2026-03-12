import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/application_model.dart';

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.SUBMITTED:
        return Colors.blue;
      case ApplicationStatus.MISSING_CV:
        return Colors.orange;
      case ApplicationStatus.UNDER_REVIEW:
        return Colors.orange;
      case ApplicationStatus.FORWARDED_TO_HR:
        return Colors.purple;
      case ApplicationStatus.HR_CALLED:
        return Colors.indigo;
      case ApplicationStatus.INTERVIEW_SCHEDULED:
        return Colors.teal;
      case ApplicationStatus.CONTRACT_SIGNED:
        return Colors.green;
      case ApplicationStatus.REJECTED:
        return Colors.red;
      case ApplicationStatus.WITHDRAWN:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.SUBMITTED:
        return Icons.mail_outline;
      case ApplicationStatus.MISSING_CV:
        return Icons.warning_amber;
      case ApplicationStatus.UNDER_REVIEW:
        return Icons.search;
      case ApplicationStatus.FORWARDED_TO_HR:
        return Icons.forward_to_inbox;
      case ApplicationStatus.HR_CALLED:
        return Icons.phone;
      case ApplicationStatus.INTERVIEW_SCHEDULED:
        return Icons.event;
      case ApplicationStatus.CONTRACT_SIGNED:
        return Icons.check_circle;
      case ApplicationStatus.REJECTED:
        return Icons.cancel;
      case ApplicationStatus.WITHDRAWN:
        return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Candidate info and status
              Row(
                children: [
                  // Candidate avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: application.candidateImageUrl != null
                        ? NetworkImage(application.candidateImageUrl!)
                        : null,
                    child: application.candidateImageUrl == null
                        ? Text(
                            application.candidateName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Candidate name and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.candidateName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(application.submittedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(application.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          application.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Job info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.jobTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            application.jobCompany,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Cover letter preview (if available)
              if (application.coverLetter != null &&
                  application.coverLetter!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  application.coverLetter!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],

              // Footer: Additional info
              const SizedBox(height: 12),
              Row(
                children: [
                  if (application.cvUrl != null) ...[
                    Icon(Icons.attach_file, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'CV Attached',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (application.autoForwarded) ...[
                    Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-forwarded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
