import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/suggestion_attachment_response.dart';
import '../../data/models/suggestion_status.dart';
import '../../data/models/support_suggestion_response.dart';

class SuggestionCard extends StatefulWidget {
  final SupportSuggestionResponse suggestion;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Future<void> Function(int attachmentId, String fileName)? onDownloadAttachment;
  final Future<void> Function(int attachmentId)? onDeleteAttachment;
  final Future<void> Function()? onAddAttachments;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.onEdit,
    this.onDelete,
    this.onDownloadAttachment,
    this.onDeleteAttachment,
    this.onAddAttachments,
  });

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  bool _isExpanded = false;
  int? _loadingAttachmentId;

  Color _getStatusColor(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.NEW:
        return AppTheme.secondaryColor;
      case SuggestionStatus.REVIEWING:
        return AppTheme.warningColor;
      case SuggestionStatus.PLANNED:
        return AppTheme.primaryColor;
      case SuggestionStatus.IN_PROGRESS:
        return const Color(0xFF8B5CF6);
      case SuggestionStatus.COMPLETED:
        return AppTheme.successColor;
      case SuggestionStatus.REJECTED:
        return AppTheme.errorColor;
      case SuggestionStatus.CLOSED:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getStatusIcon(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.NEW:
        return Icons.fiber_new_rounded;
      case SuggestionStatus.REVIEWING:
        return Icons.rate_review_rounded;
      case SuggestionStatus.PLANNED:
        return Icons.event_available_rounded;
      case SuggestionStatus.IN_PROGRESS:
        return Icons.pending_actions_rounded;
      case SuggestionStatus.COMPLETED:
        return Icons.check_circle_rounded;
      case SuggestionStatus.REJECTED:
        return Icons.cancel_rounded;
      case SuggestionStatus.CLOSED:
        return Icons.archive_rounded;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  String _formatDetailedDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (difference.inDays == 0) {
      return 'Today at $hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday at $hour:$minute $period';
    } else {
      return '$weekday, $month ${dateTime.day}, ${dateTime.year} at $hour:$minute $period';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.startsWith('image/')) return Icons.image_outlined;
    if (contentType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (contentType.contains('word') || contentType.contains('document')) return Icons.description_outlined;
    if (contentType.contains('sheet') || contentType.contains('excel')) return Icons.table_chart_outlined;
    if (contentType.startsWith('video/')) return Icons.video_file_outlined;
    if (contentType.startsWith('audio/')) return Icons.audio_file_outlined;
    if (contentType.contains('zip') || contentType.contains('compressed')) return Icons.folder_zip_outlined;
    return Icons.attach_file;
  }

  Widget _buildAttachmentsSection() {
    final attachments = widget.suggestion.attachments;
    final isNew = widget.suggestion.status == SuggestionStatus.NEW;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 8),
            Text(
              'Attachments',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (isNew && attachments.length < 5 && widget.onAddAttachments != null)
              InkWell(
                onTap: widget.onAddAttachments,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Text(
            'No attachments',
            style: TextStyle(
              color: AppTheme.textHintColor,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...attachments.map((a) => _buildAttachmentRow(a, isNew)),
      ],
    );
  }

  Widget _buildAttachmentRow(SuggestionAttachmentResponse attachment, bool canDelete) {
    final isLoading = _loadingAttachmentId == attachment.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(attachment.contentType),
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(attachment.fileSize),
                  style: TextStyle(fontSize: 11, color: AppTheme.textHintColor),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (widget.onDownloadAttachment != null)
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 18),
                color: AppTheme.primaryColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Download',
                onPressed: () async {
                  setState(() => _loadingAttachmentId = attachment.id);
                  await widget.onDownloadAttachment!(attachment.id, attachment.fileName);
                  if (mounted) setState(() => _loadingAttachmentId = null);
                },
              ),
            if (canDelete && widget.onDeleteAttachment != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.errorColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Delete',
                onPressed: () async {
                  setState(() => _loadingAttachmentId = attachment.id);
                  await widget.onDeleteAttachment!(attachment.id);
                  if (mounted) setState(() => _loadingAttachmentId = null);
                },
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.suggestion.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(widget.suggestion.status),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.suggestion.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppTheme.textHintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(widget.suggestion.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textHintColor,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                              if (widget.suggestion.attachments.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundSecondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        size: 11,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.suggestion.attachments.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.suggestion.adminResponse != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        size: 11,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Admin replied',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: _isExpanded ? 'Collapse' : 'Expand',
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.suggestion.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimaryColor,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Created At
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDetailedDateTime(widget.suggestion.createdAt),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Admin Response
                  if (widget.suggestion.adminResponse != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Response',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.suggestion.adminResponse!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textPrimaryColor,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Updated At
                  if (widget.suggestion.updatedAt != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.update,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Updated',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDetailedDateTime(widget.suggestion.updatedAt!),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Attachments
                  _buildAttachmentsSection(),
                  // Edit / Delete buttons (only for NEW suggestions)
                  if (widget.suggestion.status == SuggestionStatus.NEW &&
                      (widget.onEdit != null || widget.onDelete != null)) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.onEdit != null)
                          TextButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        if (widget.onDelete != null) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: widget.onDelete,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
