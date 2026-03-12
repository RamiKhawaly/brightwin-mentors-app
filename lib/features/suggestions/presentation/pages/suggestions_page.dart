import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/suggestion_status.dart';
import '../../data/models/support_suggestion_request.dart';
import '../../data/models/support_suggestion_response.dart';
import '../../data/repositories/suggestions_repository.dart';
import '../widgets/suggestion_card.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> with SingleTickerProviderStateMixin {
  late final SuggestionsRepository _repository;
  late final DioClient _dioClient;
  late TabController _tabController;

  List<SupportSuggestionResponse> _allSuggestions = [];
  List<SupportSuggestionResponse> _pendingSuggestions = [];
  List<SupportSuggestionResponse> _completedSuggestions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dioClient = DioClient(const FlutterSecureStorage());
    _repository = SuggestionsRepository(_dioClient);
    _loadSuggestions();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _repository.getAllSuggestions();

      if (mounted) {
        setState(() {
          _allSuggestions = suggestions;
          _pendingSuggestions = suggestions.where((s) =>
            s.status == SuggestionStatus.NEW ||
            s.status == SuggestionStatus.REVIEWING ||
            s.status == SuggestionStatus.PLANNED ||
            s.status == SuggestionStatus.IN_PROGRESS
          ).toList();
          _completedSuggestions = suggestions.where((s) =>
            s.status == SuggestionStatus.COMPLETED ||
            s.status == SuggestionStatus.REJECTED ||
            s.status == SuggestionStatus.CLOSED
          ).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load suggestions: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshSuggestions() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadSuggestions();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _downloadAttachment(int attachmentId, String fileName) async {
    try {
      final bytes = await _repository.downloadAttachment(attachmentId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteAttachment(int attachmentId) async {
    try {
      await _repository.deleteAttachment(attachmentId);
      await _refreshSuggestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete attachment: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _addAttachmentsToSuggestion(SupportSuggestionResponse suggestion) async {
    final remaining = 5 - suggestion.attachments.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 attachments allowed per suggestion.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final files = result.files.take(remaining).toList();

    try {
      await _repository.addAttachments(suggestion.id, files);
      await _refreshSuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} attachment(s) added.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add attachments: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showCreateSuggestionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<PlatformFile> selectedFiles = [];
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('New Suggestion'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Share your ideas to help us improve the platform',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      if (_appVersion.isNotEmpty)
                        Text(
                          'v$_appVersion',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Brief summary of your suggestion',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      if (value.trim().length > 200) {
                        return 'Title must not exceed 200 characters';
                      }
                      return null;
                    },
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your suggestion in detail (at least 20 characters)',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 20) {
                        return 'Description must be at least 20 characters';
                      }
                      if (value.trim().length > 5000) {
                        return 'Description must not exceed 5000 characters';
                      }
                      return null;
                    },
                    maxLines: 5,
                    maxLength: 5000,
                  ),
                  const SizedBox(height: 16),
                  _buildFilePickerSection(
                    selectedFiles: selectedFiles,
                    onChanged: (files) => setDialogState(() => selectedFiles = files),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isSubmitting = true);
                        final success = await _createSuggestion(
                          titleController.text.trim(),
                          descriptionController.text.trim(),
                          attachments: selectedFiles.isNotEmpty ? selectedFiles : null,
                        );
                        if (success && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        } else if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSuggestionDialog(SupportSuggestionResponse suggestion) {
    final titleController = TextEditingController(text: suggestion.title);
    final descriptionController = TextEditingController(text: suggestion.description);
    final formKey = GlobalKey<FormState>();
    List<PlatformFile> newFiles = [];
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Edit Suggestion'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Brief summary of your suggestion',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      if (value.trim().length > 200) {
                        return 'Title must not exceed 200 characters';
                      }
                      return null;
                    },
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your suggestion in detail',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 20) {
                        return 'Description must be at least 20 characters';
                      }
                      if (value.trim().length > 5000) {
                        return 'Description must not exceed 5000 characters';
                      }
                      return null;
                    },
                    maxLines: 5,
                    maxLength: 5000,
                  ),
                  const SizedBox(height: 16),
                  _buildFilePickerSection(
                    selectedFiles: newFiles,
                    maxFiles: 5 - suggestion.attachments.length,
                    onChanged: (files) => setDialogState(() => newFiles = files),
                    hint: suggestion.attachments.isNotEmpty
                        ? '${suggestion.attachments.length}/5 attached — add more below'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isSubmitting = true);
                        final success = await _updateSuggestion(
                          suggestion.id,
                          titleController.text.trim(),
                          descriptionController.text.trim(),
                          newAttachments: newFiles.isNotEmpty ? newFiles : null,
                        );
                        if (success && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        } else if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerSection({
    required List<PlatformFile> selectedFiles,
    required void Function(List<PlatformFile>) onChanged,
    int maxFiles = 5,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.backgroundSecondary),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                'Attachments',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (selectedFiles.length < maxFiles)
                TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      withData: true,
                      type: FileType.any,
                    );
                    if (result != null) {
                      final remaining = maxFiles - selectedFiles.length;
                      final merged = List<PlatformFile>.from(selectedFiles)
                        ..addAll(result.files.take(remaining));
                      onChanged(merged);
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Files'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(fontSize: 11, color: AppTheme.textHintColor),
            ),
          ],
          if (selectedFiles.isEmpty && hint == null) ...[
            const SizedBox(height: 4),
            Text(
              'Optional · max $maxFiles files · 10MB each',
              style: TextStyle(fontSize: 11, color: AppTheme.textHintColor),
            ),
          ],
          if (selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...selectedFiles.asMap().entries.map((entry) {
              final file = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      _fileIconForName(file.name),
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFileSize(file.size),
                      style: TextStyle(fontSize: 11, color: AppTheme.textHintColor),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        final updated = List<PlatformFile>.from(selectedFiles)..removeAt(entry.key);
                        onChanged(updated);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData _fileIconForName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) return Icons.image_outlined;
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_outlined;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.video_file_outlined;
    if (['mp3', 'wav'].contains(ext)) return Icons.audio_file_outlined;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip_outlined;
    return Icons.attach_file;
  }

  Future<bool> _updateSuggestion(
    int id,
    String title,
    String description, {
    List<PlatformFile>? newAttachments,
  }) async {
    try {
      final request = SupportSuggestionRequest(
        title: title,
        description: description,
      );

      await _repository.updateSuggestion(id, request);

      if (newAttachments != null && newAttachments.isNotEmpty) {
        await _repository.addAttachments(id, newAttachments);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _refreshSuggestions();
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update suggestion: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    }
  }

  void _showDeleteConfirmDialog(SupportSuggestionResponse suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text('Delete Suggestion'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${suggestion.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteSuggestion(suggestion.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSuggestion(int id) async {
    try {
      await _repository.deleteSuggestion(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion deleted successfully.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _refreshSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete suggestion: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _createSuggestion(
    String title,
    String description, {
    List<PlatformFile>? attachments,
  }) async {
    try {
      final versionSuffix = _appVersion.isNotEmpty ? '\n\n---\nApp version: $_appVersion' : '';
      final request = SupportSuggestionRequest(
        title: title,
        description: '$description$versionSuffix',
      );

      await _repository.createSuggestion(request, attachments: attachments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion submitted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _refreshSuggestions();
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit suggestion: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions & Support'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshSuggestions,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.backgroundSecondary,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('All'),
                      if (_allSuggestions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_allSuggestions.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (_pendingSuggestions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_pendingSuggestions.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Resolved'),
                      if (_completedSuggestions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_completedSuggestions.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSuggestionsList(_allSuggestions, 'No suggestions yet'),
                      _buildSuggestionsList(_pendingSuggestions, 'No pending suggestions'),
                      _buildSuggestionsList(_completedSuggestions, 'No resolved suggestions'),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSuggestionDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Suggestion'),
      ),
    );
  }

  Widget _buildSuggestionsList(List<SupportSuggestionResponse> suggestions, String emptyMessage) {
    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 64,
                color: AppTheme.textHintColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your ideas to improve the platform',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSuggestions,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return SuggestionCard(
            key: ValueKey(suggestion.id),
            suggestion: suggestion,
            onEdit: () => _showEditSuggestionDialog(suggestion),
            onDelete: () => _showDeleteConfirmDialog(suggestion),
            onDownloadAttachment: _downloadAttachment,
            onDeleteAttachment: _deleteAttachment,
            onAddAttachments: () => _addAttachmentsToSuggestion(suggestion),
          );
        },
      ),
    );
  }
}
