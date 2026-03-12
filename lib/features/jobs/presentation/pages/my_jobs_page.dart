import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/job_response_model.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../widgets/available_jobs_tab.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late final JobRepositoryImpl _jobRepository;
  late final TabController _tabController;

  List<JobResponseModel> _allJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _jobRepository = JobRepositoryImpl(dioClient);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jobs = await _jobRepository.getMyJobs();
      if (mounted) {
        setState(() {
          _allJobs = _sortJobsByStatus(jobs);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<JobResponseModel> _sortJobsByStatus(List<JobResponseModel> jobs) {
    final sortedJobs = List<JobResponseModel>.from(jobs);
    sortedJobs.sort((a, b) {
      final aStatus = (a.status ?? '').toUpperCase();
      final bStatus = (b.status ?? '').toUpperCase();

      int getPriority(String status) {
        if (status == 'PENDING_APPROVAL') return 0;
        if (status == 'OPEN') return 1;
        if (status == 'DRAFT') return 2;
        if (status == 'CLOSED') return 3;
        return 4;
      }

      return getPriority(aStatus).compareTo(getPriority(bStatus));
    });

    return sortedJobs;
  }

  @override
  Widget build(BuildContext context) {
    final isMyJobsTab = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isMyJobsTab ? _loadJobs : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Jobs'),
            Tab(text: 'Available'),
          ],
          indicatorColor: const Color(0xFF2bb5a3),
          labelColor: const Color(0xFF2bb5a3),
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyJobsBody(),
            const AvailableJobsTab(),
          ],
        ),
      ),
      floatingActionButton: isMyJobsTab
          ? FloatingActionButton.extended(
              onPressed: () => _showJobPostingOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
            )
          : null,
    );
  }

  void _showJobPostingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Post a Job',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add the job',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: const Text('Import from URL'),
                subtitle: const Text('Paste a job link and AI will extract details'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await context.push('${AppRoutes.jobPosting}/import');
                  if (result == true) {
                    _loadJobs();
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit),
                ),
                title: const Text('Create Manually'),
                subtitle: const Text('Fill in all job details yourself'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await context.push(AppRoutes.jobPosting);
                  if (result == true) {
                    _loadJobs();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyJobsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading jobs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No jobs yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Post your first job to get started!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allJobs.length,
        itemBuilder: (context, index) => _buildJobItem(_allJobs[index]),
      ),
    );
  }

  Widget _buildJobItem(JobResponseModel job) {
    final status = (job.status ?? '').toUpperCase();
    final statusInfo = _getStatusInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleViewDetails(job),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colored strip with status
              Container(
                width: 32,
                color: statusInfo['color'].withOpacity(0.15),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      statusInfo['shortText'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusInfo['color'],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.business, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.company,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (job.location != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    job.location!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (status == 'PENDING_APPROVAL' || status == 'DRAFT' || status == 'CLOSED') ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            if (status == 'PENDING_APPROVAL')
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _handleApprove(job),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text('Approve'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            if (status == 'DRAFT' || status == 'CLOSED')
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _handlePublish(job),
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('Publish'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return {
          'color': Colors.orange,
          'shortText': 'PENDING',
        };
      case 'OPEN':
        return {
          'color': Colors.green,
          'shortText': 'LIVE',
        };
      case 'CLOSED':
        return {
          'color': Colors.grey,
          'shortText': 'CLOSED',
        };
      case 'DRAFT':
        return {
          'color': Colors.blue,
          'shortText': 'DRAFT',
        };
      default:
        return {
          'color': Colors.grey,
          'shortText': status,
        };
    }
  }

  Future<void> _handleApprove(JobResponseModel job) async {
    try {
      await _jobRepository.approveJob(job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${job.title}" approved!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePublish(JobResponseModel job) async {
    try {
      await _jobRepository.publishJob(job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${job.title}" published!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnpublish(JobResponseModel job) async {
    try {
      await _jobRepository.unpublishJob(job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "${job.title}" unpublished!'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unpublish: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleViewDetails(JobResponseModel job) async {
    final result = await context.push(AppRoutes.jobDetail, extra: job);
    if (result == true) {
      _loadJobs();
    }
  }
}
