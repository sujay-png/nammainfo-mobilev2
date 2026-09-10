import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../models/profile.dart';

class ServicesSection extends StatelessWidget {
  final List<ServiceItem> services;
  final String? businessName;
  const ServicesSection({super.key, required this.services, this.businessName});

  void _openDetail(BuildContext context, ServiceItem s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ServiceDetailSheet(service: s, businessName: businessName),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Text(
        'No services added yet. Add them from Edit Card.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, i) {
        final s = services[i];
        return InkWell(
          onTap: () => _openDetail(context, s),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront_outlined, size: 20),
                const Spacer(),
                Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Tap ›', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceDetailSheet extends StatelessWidget {
  final ServiceItem service;
  final String? businessName;
  const _ServiceDetailSheet({required this.service, this.businessName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(service.name, style: theme.textTheme.headlineSmall),
          if (service.priceRange != null) ...[
            const SizedBox(height: 6),
            Text(service.priceRange!, style: theme.textTheme.titleSmall),
          ],
          if (service.description != null) ...[
            const SizedBox(height: 12),
            Text(service.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Enquire now'),
            onPressed: () {
              final text = Uri.encodeComponent(
                'Hi, I\'m interested in "${service.name}"'
                '${businessName != null ? ' from $businessName' : ''}.',
              );
              launchUrl(
                Uri.parse('https://wa.me/?text=$text'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
      ),
    );
  }
}
