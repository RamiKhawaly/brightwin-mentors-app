import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/linkedin_person_response.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'linkedin_job_selection_page.dart';

/// Shows the fetched LinkedIn profile data for the user to review.
/// On confirm: saves the profile then pushes [LinkedInJobSelectionPage].
class LinkedInProfileApprovalPage extends StatefulWidget {
  final LinkedInPersonResponse person;

  const LinkedInProfileApprovalPage({
    super.key,
    required this.person,
  });

  @override
  State<LinkedInProfileApprovalPage> createState() =>
      _LinkedInProfileApprovalPageState();
}

class _LinkedInProfileApprovalPageState
    extends State<LinkedInProfileApprovalPage> {
  late final ProfileRepositoryImpl _repo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = ProfileRepositoryImpl(DioClient(const FlutterSecureStorage()));
  }

  Future<void> _confirm() async {
    final person = widget.person;

    setState(() => _isSaving = true);

    try {
      await _repo.saveLinkedInProfile(person);

      if (!mounted) return;
      setState(() => _isSaving = false);

      // Push job selection — it will pop with true when done
      final done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LinkedInJobSelectionPage(person: person),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Your Profile')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(p),
                  if (p.summary != null && p.summary!.isNotEmpty)
                    _buildSection('About', [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          p.summary!,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5),
                        ),
                      ),
                    ]),
                  if (p.experience.isNotEmpty || p.currentCompany != null)
                    _buildExperienceSection(p),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                Text(
                  'This is the profile data we found. '
                  'You can edit details later from your profile page.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Confirm & Continue',
                  onPressed: _isSaving ? () {} : _confirm,
                  isLoading: _isSaving,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(LinkedInPersonResponse p) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          _buildAvatar(p),
          const SizedBox(height: 16),
          Text(
            p.displayName,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (p.headline != null) ...[
            const SizedBox(height: 6),
            Text(
              p.headline!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
          if (p.location != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(p.location!,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ],
          if (p.currentCompany != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${p.currentCompany!.title} @ ${p.currentCompany!.company}',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          if ((p.followers ?? 0) > 0 || (p.connections ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if ((p.followers ?? 0) > 0)
                  _Chip(
                      icon: Icons.people_outline,
                      label: '${p.followers} followers'),
                if ((p.followers ?? 0) > 0 && (p.connections ?? 0) > 0)
                  const SizedBox(width: 8),
                if ((p.connections ?? 0) > 0)
                  _Chip(
                      icon: Icons.handshake_outlined,
                      label: '${p.connections} connections'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(LinkedInPersonResponse p) {
    if (p.imgUrl != null && p.imgUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: Image.network(
          p.imgUrl!,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(p),
        ),
      );
    }
    return _initialsAvatar(p);
  }

  Widget _initialsAvatar(LinkedInPersonResponse p) {
    final letters = p.displayName
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letters,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  // ─── experience ──────────────────────────────────────────────────────────

  Widget _buildExperienceSection(LinkedInPersonResponse p) {
    final items = <_ExpItem>[];

    if (p.currentCompany != null) {
      final cc = p.currentCompany!;
      items.add(_ExpItem(
        company: cc.company,
        title: cc.title,
        startDate: cc.startDate,
        endDate: null,
        isCurrent: true,
        location: cc.location,
      ));
    }

    for (final e in p.experience.where((e) => !e.isCurrent)) {
      items.add(_ExpItem(
        company: e.company,
        title: e.title,
        startDate: e.startDate,
        endDate: e.endDate,
        isCurrent: false,
        location: e.location,
        description: e.description,
      ));
    }

    return _buildSection(
      'Experience',
      items
          .map((item) => _ExperienceTile(item: item))
          .toList(),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── small data helpers ───────────────────────────────────────────────────

class _ExpItem {
  final String company;
  final String title;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? location;
  final String? description;

  const _ExpItem({
    required this.company,
    required this.title,
    this.startDate,
    this.endDate,
    required this.isCurrent,
    this.location,
    this.description,
  });

  String get dateRange {
    final start = _fmt(startDate);
    if (isCurrent) return start != null ? '$start – Present' : 'Current';
    final end = _fmt(endDate);
    if (start == null && end == null) return '';
    return '${start ?? '?'} – ${end ?? '?'}';
  }

  static String? _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.isEmpty) return raw;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final year = parts[0];
    if (parts.length >= 2) {
      final month = int.tryParse(parts[1]) ?? 0;
      if (month > 0 && month <= 12) return '${months[month]} $year';
    }
    return year;
  }
}

class _ExperienceTile extends StatelessWidget {
  final _ExpItem item;

  const _ExperienceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business_outlined,
                color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(item.company,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[700])),
                if (item.dateRange.isNotEmpty)
                  Text(item.dateRange,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                if (item.location != null)
                  Text(item.location!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
