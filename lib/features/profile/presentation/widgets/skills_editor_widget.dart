import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/profile_preview_model.dart';
import '../../data/models/skill_model.dart';

class SkillsEditorWidget extends StatefulWidget {
  final List<SkillPreviewModel> initialSkills;
  final void Function(List<SkillPreviewModel> skills) onChanged;

  const SkillsEditorWidget({
    super.key,
    required this.initialSkills,
    required this.onChanged,
  });

  @override
  State<SkillsEditorWidget> createState() => _SkillsEditorWidgetState();
}

class _SkillsEditorWidgetState extends State<SkillsEditorWidget> {
  late List<SkillPreviewModel> _skills;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.initialSkills);
  }

  void _notifyChanged() {
    widget.onChanged(List.unmodifiable(_skills));
  }

  void _removeSkill(int index) {
    setState(() => _skills.removeAt(index));
    _notifyChanged();
  }

  Future<void> _showAddSkillDialog() async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    var selectedLevel = SkillLevel.INTERMEDIATE;
    int? selectedYears;

    final result = await showDialog<SkillPreviewModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name *',
                    hintText: 'e.g. Flutter, Python',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g. Programming, Design',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Level', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<SkillLevel>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SkillLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedLevel = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'e.g. 3',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    selectedYears = int.tryParse(val.trim());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  ctx,
                  SkillPreviewModel(
                    name: name,
                    category: categoryController.text.trim().isNotEmpty
                        ? categoryController.text.trim()
                        : null,
                    level: selectedLevel,
                    yearsOfExperience: selectedYears,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _skills.add(result));
      _notifyChanged();
    }
  }

  Color _levelColor(SkillLevel? level) {
    switch (level) {
      case SkillLevel.BEGINNER:
        return Colors.blue.shade300;
      case SkillLevel.INTERMEDIATE:
        return AppTheme.primaryColor;
      case SkillLevel.ADVANCED:
        return AppTheme.warningColor;
      case SkillLevel.EXPERT:
        return AppTheme.successColor;
      case null:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._skills.asMap().entries.map((entry) {
              final index = entry.key;
              final skill = entry.value;
              return Chip(
                label: Text(
                  skill.level != null
                      ? '${skill.name} · ${skill.level!.displayName}'
                      : skill.name,
                  style: const TextStyle(fontSize: 13),
                ),
                backgroundColor: _levelColor(skill.level).withValues(alpha: 0.12),
                side: BorderSide(color: _levelColor(skill.level).withValues(alpha: 0.4)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeSkill(index),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
              label: const Text(
                'Add Skill',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 13),
              ),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
              side: const BorderSide(color: AppTheme.primaryColor, width: 1),
              onPressed: _showAddSkillDialog,
            ),
          ],
        ),
        if (_skills.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No skills added yet. Tap "Add Skill" to get started.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
