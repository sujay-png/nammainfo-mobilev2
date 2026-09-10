import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Shared collapsible "section" used across the rich profile screen —
/// mirrors the Figma design's progressive-disclosure accordions with an
/// item-count badge, all collapsed by default.
class AccordionSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Widget child;
  final bool initiallyExpanded;

  const AccordionSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
  });

  @override
  State<AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<AccordionSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.ink700 : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title, style: theme.textTheme.titleMedium),
                  ),
                  if (widget.count != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.ink700 : AppColors.gray100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
