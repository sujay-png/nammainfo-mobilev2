import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme.dart';
import '../../../models/profile.dart';

class BankingSection extends StatelessWidget {
  final List<BankAccount> accounts;
  const BankingSection({super.key, required this.accounts});

  void _copy(BuildContext context, String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what copied')));
  }

  void _showUpiQr(BuildContext context, BankAccount a) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: 'upi://pay?pa=${a.upiId}', size: 220),
              const SizedBox(height: 14),
              Text(a.upiId ?? '', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, a.upiId ?? '', 'UPI ID'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy UPI ID'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text(
        'No banking details added yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: accounts
          .map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.label, style: Theme.of(context).textTheme.titleSmall),
                        if (a.accountNumber != null)
                          Text('A/C •••• ${a.accountNumber!.length > 4 ? a.accountNumber!.substring(a.accountNumber!.length - 4) : a.accountNumber}',
                              style: Theme.of(context).textTheme.bodySmall),
                        if (a.upiId != null)
                          Text(a.upiId!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (a.upiId != null)
                    IconButton(
                      icon: const Icon(Icons.qr_code, size: 20),
                      onPressed: () => _showUpiQr(context, a),
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    onPressed: () => _copy(
                      context,
                      a.upiId ?? a.accountNumber ?? '',
                      a.upiId != null ? 'UPI ID' : 'Account number',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
