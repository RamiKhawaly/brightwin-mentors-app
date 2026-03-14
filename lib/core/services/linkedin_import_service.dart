import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/profile/data/models/linkedin_person_response.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../network/dio_client.dart';

enum LinkedInImportStatus { idle, running, done, failed }

/// Singleton that manages the LinkedIn by-name profile import in the background.
///
/// Start the import via [start]. The service runs the POST + polling loop
/// asynchronously and notifies listeners as the status changes.
/// The result is held in [profiles] until [reset] is called.
///
/// The taskId is persisted to secure storage so that polling can resume
/// automatically if the app is restarted while an import is in progress.
class LinkedInImportService extends ChangeNotifier {
  LinkedInImportService._();
  static final instance = LinkedInImportService._();

  static const _storage = FlutterSecureStorage();
  static const _taskIdKey = 'linkedin_import_task_id';

  LinkedInImportStatus _status = LinkedInImportStatus.idle;
  List<LinkedInPersonResponse> _profiles = [];
  String? _error;

  LinkedInImportStatus get status => _status;
  List<LinkedInPersonResponse> get profiles => _profiles;
  String? get error => _error;

  bool get isActive => _status != LinkedInImportStatus.idle;

  /// Called on app startup. If a taskId was saved from a previous run,
  /// resumes polling without re-initiating the POST.
  Future<void> resumeIfPending() async {
    final savedTaskId = await _storage.read(key: _taskIdKey);
    if (savedTaskId == null) return;

    print('🔄 Resuming LinkedIn import for taskId: $savedTaskId');
    _status = LinkedInImportStatus.running;
    _profiles = [];
    _error = null;
    notifyListeners();

    _runPolling(savedTaskId);
  }

  /// Kicks off the background import. Safe to call multiple times — ignored
  /// while already running.
  Future<void> start() async {
    if (_status == LinkedInImportStatus.running) return;

    _status = LinkedInImportStatus.running;
    _profiles = [];
    _error = null;
    notifyListeners();

    try {
      final repo = ProfileRepositoryImpl(
        DioClient(const FlutterSecureStorage()),
      );
      final (taskId, immediate) = await repo.initiateLinkedInByNameSearch();

      // Server returned results immediately — no polling needed
      if (immediate != null) {
        await _storage.delete(key: _taskIdKey);
        if (immediate.isEmpty) {
          _error = 'No LinkedIn profile was found for your name.\n'
              'Try the "Import by URL" option instead.';
          _status = LinkedInImportStatus.failed;
        } else {
          _profiles = immediate;
          _status = LinkedInImportStatus.done;
        }
        notifyListeners();
        return;
      }

      // Persist taskId so we can resume after a restart
      if (taskId.isNotEmpty) {
        await _storage.write(key: _taskIdKey, value: taskId);
        _runPolling(taskId);
      } else {
        throw Exception('No taskId returned and no immediate result');
      }
    } catch (e) {
      await _storage.delete(key: _taskIdKey);
      _error = e.toString();
      _status = LinkedInImportStatus.failed;
      notifyListeners();
    }
  }

  void _runPolling(String taskId) {
    _poll(taskId);
  }

  Future<void> _poll(String taskId) async {
    try {
      final repo = ProfileRepositoryImpl(
        DioClient(const FlutterSecureStorage()),
      );
      final profiles = await repo.pollLinkedInByNameStatus(taskId);
      await _storage.delete(key: _taskIdKey);

      if (profiles.isEmpty) {
        _error = 'No LinkedIn profile was found for your name.\n'
            'Try the "Import by URL" option instead.';
        _status = LinkedInImportStatus.failed;
      } else {
        _profiles = profiles;
        _status = LinkedInImportStatus.done;
      }
    } catch (e) {
      await _storage.delete(key: _taskIdKey);
      _error = e.toString();
      _status = LinkedInImportStatus.failed;
    }
    notifyListeners();
  }

  void retry() => start();

  void reset() {
    _storage.delete(key: _taskIdKey);
    _status = LinkedInImportStatus.idle;
    _profiles = [];
    _error = null;
    notifyListeners();
  }
}
