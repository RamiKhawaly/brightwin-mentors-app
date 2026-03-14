import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/linkedin_job_response.dart';
import '../../data/models/linkedin_person_response.dart';
import '../../data/repositories/profile_repository_impl.dart';

/// Shows open positions at the mentor's current company and lets the user
/// choose which to own. Selected jobs are assigned to the mentor; the rest
/// go to the unassigned pool for other mentors to claim.
///
/// Can be used in two ways:
/// - After LinkedIn profile approval: pass [person] to supply company info.
/// - Standalone (from the Jobs screen): pass nothing — the page fetches the
///   mentor's profile to resolve their current company automatically.
class LinkedInJobSelectionPage extends StatefulWidget {
  /// LinkedIn profile result — used to extract current company info.
  /// Optional when [companyName] is provided or when calling standalone.
  final LinkedInPersonResponse? person;

  /// Override company name directly (takes precedence over [person]).
  final String? companyName;

  /// Override company LinkedIn/website URL (used alongside [companyName]).
  final String? companyUrl;

  const LinkedInJobSelectionPage({
    super.key,
    this.person,
    this.companyName,
    this.companyUrl,
  });

  @override
  State<LinkedInJobSelectionPage> createState() =>
      _LinkedInJobSelectionPageState();
}

class _LinkedInJobSelectionPageState
    extends State<LinkedInJobSelectionPage> {
  late final ProfileRepositoryImpl _repo;

  List<LinkedInJobResponse> _jobs = [];
  final Set<String> _selectedUrls = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _resolvedCompanyName = '';

  static const int _maxJobs = 5;

  @override
  void initState() {
    super.initState();
    _repo = ProfileRepositoryImpl(DioClient(const FlutterSecureStorage()));
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      String? name = widget.companyName ?? widget.person?.currentCompany?.company;
      String? url = widget.companyUrl ?? widget.person?.currentCompany?.companyUrl;

      // Standalone: resolve company from the mentor's profile
      if (name == null || name.isEmpty) {
        print('🏢 No company supplied — fetching from profile');
        final profile = await _repo.getProfile();
        name = profile.currentCompany?.name ??
            profile.currentCompanyInfo?.companyName;
        url ??= profile.currentCompany?.linkedInUrl ??
            profile.currentCompanyInfo?.linkedInUrl;
      }

      if (name == null || name.isEmpty) {
        setState(() {
          _isLoading = false;
          _loadError =
              'No current company found on your profile.\n'
              'Update your profile with your current employer first.';
        });
        return;
      }

      _resolvedCompanyName = name;

      final all = await _repo.fetchCompanyJobs(name, url);
      if (!mounted) return;
      setState(() {
        _jobs = all.take(_maxJobs).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load job positions: ${e.toString()}';
      });
    }
  }

  Future<void> _continue() async {
    setState(() => _isSaving = true);

    try {
      await _repo.createLinkedInJobsBatch(_jobs, _selectedUrls);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save jobs: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final company = _resolvedCompanyName.isNotEmpty
        ? _resolvedCompanyName
        : widget.person?.currentCompany?.company ?? 'your company';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Job Positions'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Skip',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open positions at $company',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the roles you want to own. '
                  'Others will be available for colleagues to claim.',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(child: _buildBody()),

          // Bottom bar
          if (!_isLoading && _loadError == null && _jobs.isNotEmpty)
            _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading open positions…'),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadJobs,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_off_outlined,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No open positions found at this company right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Continue Without Jobs',
                onPressed: () => Navigator.pop(context, false),
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        final url = job.jobPostingUrl ?? '';
        final selected = _selectedUrls.contains(url);

        return _JobCard(
          job: job,
          selected: selected,
          onTap: () {
            setState(() {
              if (selected) {
                _selectedUrls.remove(url);
              } else {
                _selectedUrls.add(url);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final count = _selectedUrls.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (count > 0)
            Text(
              '$count position${count == 1 ? '' : 's'} selected — '
              'the rest will go to the unassigned pool.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Select at least one position to own, or skip.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          CustomButton(
            text: count > 0
                ? 'Confirm Selection ($count)'
                : 'Continue Without Selection',
            onPressed: _isSaving ? () {} : _continue,
            isLoading: _isSaving,
            icon: count > 0 ? Icons.check_circle_outline : Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}

// ─── job card ─────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final LinkedInJobResponse job;
  final bool selected;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Colors.grey[200]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Company logo or icon
            _buildLogo(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title ?? 'Untitled Position',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (job.companyName != null) ...[
                    const SizedBox(height: 2),
                    Text(job.companyName!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (job.location != null)
                        _Tag(
                            icon: Icons.location_on_outlined,
                            label: job.location!),
                      if (job.employmentType != null)
                        _Tag(
                            icon: Icons.work_outline,
                            label: job.employmentType!),
                      if (job.seniorityLevel != null)
                        _Tag(
                            icon: Icons.bar_chart_outlined,
                            label: job.seniorityLevel!),
                      if (job.salary != null)
                        _Tag(
                            icon: Icons.attach_money_outlined,
                            label: job.salary!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Checkbox indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (job.companyLogo != null && job.companyLogo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          job.companyLogo!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconPlaceholder(context),
        ),
      );
    }
    return _iconPlaceholder(context);
  }

  Widget _iconPlaceholder(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.business_outlined,
          color: Colors.grey, size: 22),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
