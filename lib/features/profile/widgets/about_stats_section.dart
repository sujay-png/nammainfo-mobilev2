import 'package:flutter/material.dart';
import '../../../models/profile.dart';

class AboutStatsSection extends StatelessWidget {
  final Profile profile;
  const AboutStatsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = <(String, String)>[
      if (profile.yearsInBusiness != null)
        ('${profile.yearsInBusiness}+', 'Years'),
      if (profile.clientsServed != null)
        ('${profile.clientsServed}+', 'Clients'),
      if (profile.coverageArea != null) (profile.coverageArea!, 'Coverage'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.bio?.isNotEmpty == true)
          Text(profile.bio!, style: theme.textTheme.bodyMedium)
        else
          Text(
            'Add a short description of your business from Edit Card.',
            style: theme.textTheme.bodyMedium,
          ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: stats
                .map(
                  (s) => Expanded(
                    child: Column(
                      children: [
                        Text(s.$1, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        Text(
                          s.$2,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
