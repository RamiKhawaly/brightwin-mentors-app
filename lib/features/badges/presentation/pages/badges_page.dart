import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/badge_entity.dart';
import '../widgets/badge_card.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Achievements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Earned'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBadgesList(isEarned: true),
                _buildBadgesList(isEarned: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.emoji_events,
            label: 'Total Badges',
            value: '8',
            color: AppTheme.badgeGold,
          ),
          _buildStatItem(
            icon: Icons.star,
            label: 'Total Points',
            value: '1,250',
            color: Colors.white,
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'Ranking',
            value: '#12',
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildBadgesList({required bool isEarned}) {
    final badges = isEarned ? _getEarnedBadges() : _getAvailableBadges();

    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isEarned ? 'No badges earned yet' : 'All badges earned!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isEarned
                  ? 'Keep helping job seekers to earn badges'
                  : 'Congratulations on your achievements!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return BadgeCard(badge: badges[index]);
      },
    );
  }

  List<Map<String, dynamic>> _getEarnedBadges() {
    return [
      {
        'name': 'Helpful Mentor',
        'description': 'Helped 10 job seekers',
        'type': BadgeType.helpfulMentor,
        'category': BadgeCategory.engagement,
        'requiredPoints': 10,
        'currentProgress': 10,
        'isEarned': true,
        'earnedAt': DateTime.now().subtract(const Duration(days: 15)),
        'color': AppTheme.badgeGold,
      },
      {
        'name': 'Interview Expert',
        'description': 'Conducted 5 interview simulations',
        'type': BadgeType.interviewExpert,
        'category': BadgeCategory.achievement,
        'requiredPoints': 5,
        'currentProgress': 5,
        'isEarned': true,
        'earnedAt': DateTime.now().subtract(const Duration(days: 8)),
        'color': AppTheme.badgeSilver,
      },
      {
        'name': 'Quick Responder',
        'description': 'Responded to 20 chat requests within 5 minutes',
        'type': BadgeType.quickResponder,
        'category': BadgeCategory.engagement,
        'requiredPoints': 20,
        'currentProgress': 20,
        'isEarned': true,
        'earnedAt': DateTime.now().subtract(const Duration(days: 3)),
        'color': AppTheme.badgeBronze,
      },
    ];
  }

  List<Map<String, dynamic>> _getAvailableBadges() {
    return [
      {
        'name': 'Career Guide',
        'description': 'Provide career guidance to 25 job seekers',
        'type': BadgeType.careerGuide,
        'category': BadgeCategory.achievement,
        'requiredPoints': 25,
        'currentProgress': 12,
        'isEarned': false,
        'color': AppTheme.badgeGold,
      },
      {
        'name': 'Top Referrer',
        'description': 'Successfully refer 15 candidates',
        'type': BadgeType.topReferrer,
        'category': BadgeCategory.milestone,
        'requiredPoints': 15,
        'currentProgress': 7,
        'isEarned': false,
        'color': AppTheme.badgeSilver,
      },
      {
        'name': 'Dedicated Mentor',
        'description': 'Maintain a 90% response rate for 30 days',
        'type': BadgeType.dedicatedMentor,
        'category': BadgeCategory.milestone,
        'requiredPoints': 30,
        'currentProgress': 18,
        'isEarned': false,
        'color': AppTheme.badgeBronze,
      },
    ];
  }
}
