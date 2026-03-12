import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/applications_repository.dart';
import '../widgets/application_card.dart';

class ApplicationsPage extends StatefulWidget {
  final int? jobId; // Optional: filter by job ID
  final String? jobTitle; // Optional: job title for display

  const ApplicationsPage({
    super.key,
    this.jobId,
    this.jobTitle,
  });

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> with SingleTickerProviderStateMixin {
  late final ApplicationsRepository _repository;
  List<ApplicationModel> _allApplications = [];
  List<ApplicationModel> _filteredApplications = [];
  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;
  ApplicationStatus? _selectedStatus;

  final List<ApplicationStatus?> _filterTabs = [
    null, // All
    ApplicationStatus.SUBMITTED,
    ApplicationStatus.UNDER_REVIEW,
    ApplicationStatus.FORWARDED_TO_HR,
    ApplicationStatus.INTERVIEW_SCHEDULED,
    ApplicationStatus.CONTRACT_SIGNED,
    ApplicationStatus.REJECTED,
  ];

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = ApplicationsRepository(dioClient);
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedStatus = _filterTabs[_tabController.index];
      _applyFilters();
    });
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<ApplicationModel> applications;

      if (widget.jobId != null) {
        // Load applications for specific job
        applications = await _repository.getApplicationsByJob(widget.jobId!);
      } else {
        // Load all applications
        applications = await _repository.getAllApplications();
      }

      if (mounted) {
        setState(() {
          _allApplications = applications;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _applyFilters() {
    if (_selectedStatus == null) {
      _filteredApplications = List.from(_allApplications);
    } else {
      _filteredApplications = _allApplications
          .where((app) => app.status == _selectedStatus)
          .toList();
    }

    // Sort by submission date (newest first)
    _filteredApplications.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  String _getTabLabel(ApplicationStatus? status) {
    if (status == null) return 'All';
    return status.displayName;
  }

  int _getCountForStatus(ApplicationStatus? status) {
    if (status == null) return _allApplications.length;
    return _allApplications.where((app) => app.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.jobTitle != null
        ? 'Applications - ${widget.jobTitle}'
        : 'Applications';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _filterTabs.map((status) {
            final count = _getCountForStatus(status);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getTabLabel(status)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load applications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadApplications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredApplications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _selectedStatus == null
                    ? 'No applications yet'
                    : 'No ${_selectedStatus!.displayName.toLowerCase()} applications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedStatus == null
                    ? 'Applications submitted to your jobs will appear here'
                    : 'Try selecting a different status filter',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredApplications.length,
        itemBuilder: (context, index) {
          final application = _filteredApplications[index];
          return ApplicationCard(
            application: application,
            onTap: () async {
              final result = await context.push<bool>(
                '/applications/${application.id}',
                extra: application,
              );

              if (result == true) {
                // Refresh if application was updated
                _loadApplications();
              }
            },
          );
        },
      ),
    );
  }
}
