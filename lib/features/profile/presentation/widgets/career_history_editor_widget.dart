import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/profile_preview_model.dart';
import 'experience_form_dialog.dart';

class CareerHistoryEditorWidget extends StatefulWidget {
  final List<ExperiencePreviewModel> initialExperiences;
  final void Function(List<ExperiencePreviewModel> experiences) onChanged;

  const CareerHistoryEditorWidget({
    super.key,
    required this.initialExperiences,
    required this.onChanged,
  });

  @override
  State<CareerHistoryEditorWidget> createState() =>
      _CareerHistoryEditorWidgetState();
}

class _CareerHistoryEditorWidgetState extends State<CareerHistoryEditorWidget> {
  late List<ExperiencePreviewModel> _experiences;

  @override
  void initState() {
    super.initState();
    _experiences = List.from(widget.initialExperiences);
  }

  void _notifyChanged() {
    widget.onChanged(List.unmodifiable(_experiences));
  }

  Future<void> _addExperience() async {
    final result = await showDialog<ExperiencePreviewModel>(
      context: context,
      builder: (_) => const ExperienceFormDialog(),
    );
    if (result != null) {
      setState(() => _experiences.insert(0, result));
      _notifyChanged();
    }
  }

  Future<void> _editExperience(int index) async {
    final result = await showDialog<ExperiencePreviewModel>(
      context: context,
      builder: (_) => ExperienceFormDialog(initial: _experiences[index]),
    );
    if (result != null) {
      setState(() => _experiences[index] = result);
      _notifyChanged();
    }
  }

  Future<void> _deleteExperience(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Experience'),
        content: Text(
          'Remove "${_experiences[index].position}" at "${_experiences[index].company}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _experiences.removeAt(index));
      _notifyChanged();
    }
  }

  String _formatPeriod(ExperiencePreviewModel exp) {
    final fmt = DateFormat('MMM yyyy');
    final start = exp.startDate != null ? fmt.format(exp.startDate!) : 'Unknown';
    final end = exp.currentlyWorking
        ? 'Present'
        : exp.endDate != null
            ? fmt.format(exp.endDate!)
            : 'Present';
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_experiences.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.work_history_outlined,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No career history yet. Add your work experience.',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _experiences.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final exp = _experiences[index];
              return _ExperienceCard(
                experience: exp,
                period: _formatPeriod(exp),
                onEdit: () => _editExperience(index),
                onDelete: () => _deleteExperience(index),
              );
            },
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addExperience,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Experience'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final ExperiencePreviewModel experience;
  final String period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExperienceCard({
    required this.experience,
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business_outlined,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experience.position,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  experience.company,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  period,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                if (experience.location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        experience.location!,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (experience.technologies.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: experience.technologies.take(4).map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tech,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppTheme.textSecondaryColor,
                onPressed: onEdit,
                tooltip: 'Edit',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.errorColor,
                onPressed: onDelete,
                tooltip: 'Delete',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
