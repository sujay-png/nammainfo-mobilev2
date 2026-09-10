import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme.dart';
import '../../../models/profile.dart';

/// The physical-card-style digital business card shown at the top of
/// "My Card". Tap it to flip between the front (personal/contact side)
/// and the back (company branding + NFC/QR side) with a smooth 3D
/// rotation, mirroring a real plastic card.
class BusinessCardFlip extends StatefulWidget {
  final Profile profile;
  final String qrData;
  final bool nfcActive;

  const BusinessCardFlip({
    super.key,
    required this.profile,
    required this.qrData,
    this.nfcActive = false,
  });

  @override
  State<BusinessCardFlip> createState() => _BusinessCardFlipState();
}

class _BusinessCardFlipState extends State<BusinessCardFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  bool _showingBack = false;

  void _flip() {
    if (_controller.isAnimating) return;
    setState(() => _showingBack = !_showingBack);
    if (_showingBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AspectRatio(
        aspectRatio: 1.6,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
            final showFront = angle < math.pi / 2;
            final content = showFront
                ? _CardFront(profile: widget.profile)
                : Transform(
                    alignment: Alignment.center,
                    // Un-mirror the back face's content (it's inside a
                    // parent already rotated ~180°).
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardBack(
                      profile: widget.profile,
                      qrData: widget.qrData,
                      nfcActive: widget.nfcActive,
                    ),
                  );

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(angle),
              child: content,
            );
          },
        ),
      ),
    );
  }
}

/// Shared card chrome — rounded, bordered, subtle shadow — used by both
/// faces so front/back feel like one physical object.
class _CardFace extends StatelessWidget {
  final Widget child;
  const _CardFace({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.gray200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardFront extends StatelessWidget {
  final Profile profile;
  const _CardFront({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = <_ContactRowData>[
      if (profile.phone?.isNotEmpty == true)
        _ContactRowData(Icons.call_outlined, profile.phone!),
      if (profile.email?.isNotEmpty == true)
        _ContactRowData(Icons.mail_outline, profile.email!),
      if (profile.website?.isNotEmpty == true)
        _ContactRowData(Icons.public, profile.website!),
    ];

    return _CardFace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.ownerName?.isNotEmpty == true
                          ? profile.ownerName!
                          : 'Your name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (profile.jobTitle?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.jobTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CompanyLogo(profile: profile, size: 38),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.gray200),
          const SizedBox(height: 12),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'No contact details yet',
                      style: TextStyle(color: AppColors.gray400, fontSize: 12),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final row in rows) _ContactRow(data: row),
                    ],
                  ),
          ),
          if (profile.address?.isNotEmpty == true)
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 13, color: AppColors.gray500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    profile.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.gray500, fontSize: 11),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContactRowData {
  final IconData icon;
  final String text;
  const _ContactRowData(this.icon, this.text);
}

class _ContactRow extends StatelessWidget {
  final _ContactRowData data;
  const _ContactRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.black, width: 1),
            ),
            child: Icon(data.icon, size: 12, color: AppColors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final Profile profile;
  final String qrData;
  final bool nfcActive;
  const _CardBack({required this.profile, required this.qrData, required this.nfcActive});

  @override
  Widget build(BuildContext context) {
    return _CardFace(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CompanyLogo(profile: profile, size: 56),
                const SizedBox(height: 12),
                Text(
                  profile.businessName?.isNotEmpty == true
                      ? profile.businessName!
                      : 'Your business',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.nfc,
                      size: 20,
                      color: nfcActive ? AppColors.black : AppColors.gray300,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NFC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: nfcActive ? AppColors.black : AppColors.gray300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Namma Info',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray500,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: 68,
                    backgroundColor: Colors.transparent,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final Profile profile;
  final double size;
  const _CompanyLogo({required this.profile, required this.size});

  String _initials() {
    final name = profile.businessName?.trim();
    if (name == null || name.isEmpty) return 'NI';
    final parts = name.split(RegExp(r'\s+')).take(2);
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    if (profile.logoUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: profile.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.black, width: 1.2),
      ),
      child: Text(
        _initials(),
        style: TextStyle(
          color: AppColors.black,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}
