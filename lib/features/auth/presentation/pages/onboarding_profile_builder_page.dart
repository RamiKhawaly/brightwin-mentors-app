import 'package:flutter/material.dart';

/// Onboarding step that lets the user choose how to build their profile:
/// 1. Import from LinkedIn
/// 2. Upload a CV
/// 3. Fill in manually later
class OnboardingProfileBuilderPage extends StatelessWidget {
  final VoidCallback onLinkedInTap;
  final VoidCallback onCVTap;
  final VoidCallback onManualTap;

  const OnboardingProfileBuilderPage({
    super.key,
    required this.onLinkedInTap,
    required this.onCVTap,
    required this.onManualTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Build Your Profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'A complete profile helps candidates and employers know your expertise',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Option 1: LinkedIn
          _OptionCard(
            icon: Icons.link,
            iconColor: const Color(0xFF0A66C2),
            iconBackground: const Color(0xFF0A66C2).withValues(alpha: 0.1),
            title: 'Import from LinkedIn',
            description:
                'Automatically import your work history, education, and skills from your LinkedIn profile',
            badge: 'Recommended',
            badgeColor: Colors.green,
            onTap: onLinkedInTap,
          ),

          const SizedBox(height: 16),

          // Option 2: CV
          _OptionCard(
            icon: Icons.upload_file,
            iconColor: Theme.of(context).primaryColor,
            iconBackground:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            title: 'Upload your CV',
            description:
                'Upload a PDF or Word document and our AI will extract your professional information',
            onTap: onCVTap,
          ),

          const SizedBox(height: 16),

          // Option 3: Manual
          _OptionCard(
            icon: Icons.edit_outlined,
            iconColor: Colors.grey[700]!,
            iconBackground: Colors.grey[100]!,
            title: 'Fill in manually',
            description:
                'Skip for now and complete your profile details later at your own pace',
            onTap: onManualTap,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? Colors.green)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor ?? Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
