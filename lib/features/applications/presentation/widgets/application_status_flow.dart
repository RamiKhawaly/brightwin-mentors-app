import 'package:flutter/material.dart';
import '../../data/models/application_model.dart';

/// Visual status flow widget for application progress
/// Shows mentor-relevant statuses in a visual flow with interactive steps
class ApplicationStatusFlow extends StatelessWidget {
  final ApplicationModel application;
  final bool isLoading;
  final Function(ApplicationStatus) onStatusUpdate;

  const ApplicationStatusFlow({
    super.key,
    required this.application,
    required this.isLoading,
    required this.onStatusUpdate,
  });

  // Define the mentor-relevant status flow
  static const List<ApplicationStatus> mentorFlow = [
    ApplicationStatus.SUBMITTED,
    ApplicationStatus.UNDER_REVIEW,
    ApplicationStatus.FORWARDED_TO_HR,
  ];

  // Candidate-side statuses (shown but not actionable by mentor)
  static const List<ApplicationStatus> candidateFlow = [
    ApplicationStatus.HR_CALLED,
    ApplicationStatus.INTERVIEW_SCHEDULED,
    ApplicationStatus.CONTRACT_SIGNED,
  ];

  int _getCurrentStepIndex() {
    final currentStatus = application.status;

    // Check if in mentor flow
    final mentorIndex = mentorFlow.indexOf(currentStatus);
    if (mentorIndex != -1) return mentorIndex;

    // If in candidate flow or final status, return completed mentor flow
    if (candidateFlow.contains(currentStatus) ||
        currentStatus == ApplicationStatus.REJECTED ||
        currentStatus == ApplicationStatus.WITHDRAWN) {
      return mentorFlow.length;
    }

    return 0;
  }

  bool _isStepCompleted(int stepIndex) {
    return stepIndex < _getCurrentStepIndex();
  }

  bool _isStepCurrent(int stepIndex) {
    return stepIndex == _getCurrentStepIndex();
  }

  bool _canProgressToStep(int stepIndex) {
    // Can only progress to the next step after current
    return stepIndex == _getCurrentStepIndex() + 1;
  }

  Color _getStepColor(int stepIndex) {
    if (_isStepCompleted(stepIndex)) return Colors.green;
    if (_isStepCurrent(stepIndex)) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.SUBMITTED:
        return 'Candidate\nApplied';
      case ApplicationStatus.MISSING_CV:
        return 'Missing\nCV';
      case ApplicationStatus.UNDER_REVIEW:
        return 'Under\nReview';
      case ApplicationStatus.FORWARDED_TO_HR:
        return 'Forwarded\nto HR';
      case ApplicationStatus.HR_CALLED:
        return 'HR\nContacted';
      case ApplicationStatus.INTERVIEW_SCHEDULED:
        return 'Interview\nScheduled';
      case ApplicationStatus.CONTRACT_SIGNED:
        return 'Contract\nSigned';
      case ApplicationStatus.REJECTED:
        return 'Rejected';
      case ApplicationStatus.WITHDRAWN:
        return 'Withdrawn';
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
    // Handle rejected/withdrawn status differently
    if (application.status == ApplicationStatus.REJECTED ||
        application.status == ApplicationStatus.WITHDRAWN) {
      return _buildFinalStatusCard(context);
    }

    // Handle missing CV status
    if (application.status == ApplicationStatus.MISSING_CV) {
      return _buildMissingCVCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main mentor flow
        _buildStatusFlow(context),

        const SizedBox(height: 24),

        // Show candidate progress if past mentor stage
        if (_getCurrentStepIndex() >= mentorFlow.length) ...[
          _buildCandidateProgress(context),
          const SizedBox(height: 16),
        ],

        // Action buttons for next step
        if (_getCurrentStepIndex() < mentorFlow.length) ...[
          _buildActionButtons(context),
        ],
      ],
    );
  }

  Widget _buildStatusFlow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (int i = 0; i < mentorFlow.length; i++) ...[
                // Step circle
                Expanded(
                  child: _buildStepCircle(
                    context,
                    mentorFlow[i],
                    i,
                  ),
                ),
                // Connector line (except after last step)
                if (i < mentorFlow.length - 1)
                  Expanded(
                    child: _buildConnectorLine(i),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(BuildContext context, ApplicationStatus status, int stepIndex) {
    final isCompleted = _isStepCompleted(stepIndex);
    final isCurrent = _isStepCurrent(stepIndex);
    final canProgress = _canProgressToStep(stepIndex);
    final color = _getStepColor(stepIndex);

    return GestureDetector(
      onTap: (canProgress && !isLoading)
          ? () => onStatusUpdate(status)
          : null,
      child: Column(
        children: [
          // Circle with icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? color
                  : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: canProgress ? color : Colors.grey[300]!,
                width: canProgress ? 3 : 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check
                  : _getStatusIcon(status),
              color: isCompleted || isCurrent
                  ? Colors.white
                  : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            _getStatusLabel(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? color
                  : (isCompleted ? Colors.grey[700] : Colors.grey[500]),
              height: 1.2,
            ),
          ),
          // Action hint for next step
          if (canProgress) ...[
            const SizedBox(height: 4),
            Text(
              'Tap to update',
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectorLine(int stepIndex) {
    final isCompleted = _isStepCompleted(stepIndex + 1);

    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 60),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCandidateProgress(BuildContext context) {
    final currentStatus = application.status;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Waiting for Candidate Updates',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getCandidateProgressMessage(currentStatus),
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[800],
              height: 1.4,
            ),
          ),
          if (candidateFlow.contains(currentStatus)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getStatusIcon(currentStatus),
                  color: Colors.blue[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current: ${currentStatus.displayName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getCandidateProgressMessage(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.FORWARDED_TO_HR:
        return 'The application has been forwarded to HR. The candidate will update the status when HR contacts them.';
      case ApplicationStatus.HR_CALLED:
        return 'HR has contacted the candidate. They will update when an interview is scheduled.';
      case ApplicationStatus.INTERVIEW_SCHEDULED:
        return 'An interview has been scheduled. The candidate will update after the final outcome.';
      case ApplicationStatus.CONTRACT_SIGNED:
        return 'Success! The candidate has signed the contract. Congratulations on the successful referral!';
      default:
        return 'The application is in progress.';
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final currentIndex = _getCurrentStepIndex();

    if (currentIndex >= mentorFlow.length) return const SizedBox.shrink();

    final nextStatus = currentIndex + 1 < mentorFlow.length
        ? mentorFlow[currentIndex + 1]
        : null;

    if (nextStatus == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => onStatusUpdate(nextStatus),
            icon: Icon(_getStatusIcon(nextStatus)),
            label: Text(_getActionButtonText(nextStatus)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _getStepColor(currentIndex + 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getActionButtonText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.UNDER_REVIEW:
        return 'Mark as Under Review';
      case ApplicationStatus.FORWARDED_TO_HR:
        return 'Forward Application';
      default:
        return 'Update to ${status.displayName}';
    }
  }

  Widget _buildMissingCVCard(BuildContext context) {
    final color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            'CV Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The candidate has not uploaded their CV yet. The application cannot proceed until a CV is submitted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The candidate will be notified to complete their application',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStatusCard(BuildContext context) {
    final isRejected = application.status == ApplicationStatus.REJECTED;
    final color = isRejected ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isRejected ? Icons.cancel : Icons.remove_circle_outline,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            isRejected ? 'Application Rejected' : 'Application Withdrawn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRejected
                ? 'This application has been rejected and is no longer active.'
                : 'This application was withdrawn by the candidate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
