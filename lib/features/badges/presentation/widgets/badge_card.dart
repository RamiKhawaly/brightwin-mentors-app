import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final isEarned = badge['isEarned'] as bool;
    final currentProgress = badge['currentProgress'] as int;
    final requiredPoints = badge['requiredPoints'] as int;
    final progress = currentProgress / requiredPoints;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Badge Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isEarned
                    ? (badge['color'] as Color).withOpacity(0.2)
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 32,
                color: isEarned ? badge['color'] as Color : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 16),

            // Badge Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge['name'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),

                  if (isEarned) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Earned ${_formatDate(badge['earnedAt'] as DateTime)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              badge['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentProgress/$requiredPoints',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
