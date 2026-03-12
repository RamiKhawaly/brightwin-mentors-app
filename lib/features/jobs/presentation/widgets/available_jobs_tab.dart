import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/job_response_model.dart';
import '../../data/repositories/job_repository_impl.dart';

class AvailableJobsTab extends StatefulWidget {
  const AvailableJobsTab({super.key});

  @override
  State<AvailableJobsTab> createState() => _AvailableJobsTabState();
}

class _AvailableJobsTabState extends State<AvailableJobsTab> {
  late final JobRepositoryImpl _jobRepository;
  List<JobResponseModel> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _takingOwnership = {};

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _jobRepository = JobRepositoryImpl(dioClient);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jobs = await _jobRepository.getUnassignedCompanyJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
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

  Future<void> _handleTakeOwnership(JobResponseModel job) async {
    setState(() => _takingOwnership.add(job.id));
    try {
      await _jobRepository.takeOwnership(job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now the owner of "${job.title}"!'),
            backgroundColor: const Color(0xFF2bb5a3),
          ),
        );
        _loadJobs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take ownership: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _takingOwnership.remove(job.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Error loading jobs',
                style: Theme.of(context).textTheme.titleLarge),
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

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No available jobs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No unowned jobs at your company right now.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
      ),
    );
  }

  Widget _buildJobCard(JobResponseModel job) {
    final isTaking = _takingOwnership.contains(job.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + "Available" badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe6f6f3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AVAILABLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2bb5a3),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Company
            Row(
              children: [
                Icon(Icons.business, size: 15, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  job.company,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            // Location
            if (job.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 15, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    job.location!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            // Employment type
            if (job.employmentType != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 15, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    job.employmentType!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            // Tech stack chips
            if (job.techStack != null && job.techStack!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: job.techStack!.take(5).map((tech) {
                  return Chip(
                    label: Text(
                      tech,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFFe6f6f3),
                    side: BorderSide.none,
                    labelStyle: const TextStyle(color: Color(0xFF2bb5a3)),
                  );
                }).toList(),
              ),
            ],
            // Referral bonus
            if (job.referralBonus != null && job.referralBonus! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      size: 15, color: Color(0xFF2bb5a3)),
                  const SizedBox(width: 4),
                  Text(
                    'Referral bonus: \$${job.referralBonus!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF2bb5a3),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Take ownership CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isTaking ? null : () => _handleTakeOwnership(job),
                icon: isTaking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.handshake_outlined, size: 18),
                label: Text(isTaking ? 'Claiming...' : 'Take Ownership'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03405F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
