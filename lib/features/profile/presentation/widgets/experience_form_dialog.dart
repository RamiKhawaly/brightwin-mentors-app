import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/profile_preview_model.dart';

class ExperienceFormDialog extends StatefulWidget {
  final ExperiencePreviewModel? initial;

  const ExperienceFormDialog({super.key, this.initial});

  @override
  State<ExperienceFormDialog> createState() => _ExperienceFormDialogState();
}

class _ExperienceFormDialogState extends State<ExperienceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyController;
  late final TextEditingController _positionController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _achievementsController;
  late final TextEditingController _technologiesController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _currentlyWorking = false;

  @override
  void initState() {
    super.initState();
    final exp = widget.initial;
    _companyController = TextEditingController(text: exp?.company ?? '');
    _positionController = TextEditingController(text: exp?.position ?? '');
    _locationController = TextEditingController(text: exp?.location ?? '');
    _descriptionController = TextEditingController(text: exp?.description ?? '');
    _achievementsController = TextEditingController(
      text: exp?.achievements.join('\n') ?? '',
    );
    _technologiesController = TextEditingController(
      text: exp?.technologies.join(', ') ?? '',
    );
    _startDate = exp?.startDate;
    _endDate = exp?.endDate;
    _currentlyWorking = exp?.currentlyWorking ?? false;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _achievementsController.dispose();
    _technologiesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('MMM yyyy').format(date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final achievements = _achievementsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final technologies = _technologiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final result = ExperiencePreviewModel(
      company: _companyController.text.trim(),
      position: _positionController.text.trim(),
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      startDate: _startDate,
      endDate: _currentlyWorking ? null : _endDate,
      currentlyWorking: _currentlyWorking,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      achievements: achievements,
      technologies: technologies,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Experience' : 'Edit Experience'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Company is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position / Title *',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Position is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                // Date range row
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerButton(
                        label: 'Start Date',
                        value: _formatDate(_startDate),
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _currentlyWorking
                          ? _DatePickerButton(
                              label: 'End Date',
                              value: 'Present',
                              onTap: null,
                              disabled: true,
                            )
                          : _DatePickerButton(
                              label: 'End Date',
                              value: _formatDate(_endDate),
                              onTap: () => _pickDate(false),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _currentlyWorking,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Currently working here',
                    style: TextStyle(fontSize: 14),
                  ),
                  onChanged: (val) =>
                      setState(() => _currentlyWorking = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _achievementsController,
                  decoration: const InputDecoration(
                    labelText: 'Achievements (one per line)',
                    alignLabelWithHint: true,
                    hintText: 'Led team of 5 engineers\nImproved performance by 30%',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _technologiesController,
                  decoration: const InputDecoration(
                    labelText: 'Technologies (comma-separated)',
                    hintText: 'Flutter, Dart, Firebase',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool disabled;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
          color: disabled ? Colors.grey.shade50 : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: disabled ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: disabled ? Colors.grey : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: disabled ? Colors.grey : Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
