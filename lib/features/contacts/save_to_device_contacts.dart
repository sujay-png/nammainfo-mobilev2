import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../models/profile.dart';

/// "Skip & Save to Contacts" — adds the tapped card's profile straight
/// into the phone's native address book. Requires contacts permission
/// (see platform_setup/ for the manifest/plist snippets to add).
Future<void> saveProfileToDeviceContacts(BuildContext context, Profile profile) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Contacts permission was denied.')),
      );
      return;
    }

    final nameParts = (profile.ownerName ?? '').trim().split(RegExp(r'\s+'));
    final contact = Contact()
      ..name.first = nameParts.isNotEmpty ? nameParts.first : (profile.businessName ?? 'Namma Info')
      ..name.last = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''
      ..organizations = [
        Organization(
          company: profile.businessName ?? '',
          title: profile.jobTitle ?? '',
        ),
      ];

    if (profile.phone?.isNotEmpty == true) {
      contact.phones = [Phone(profile.phone!)];
    }
    if (profile.email?.isNotEmpty == true) {
      contact.emails = [Email(profile.email!)];
    }
    if (profile.website?.isNotEmpty == true) {
      contact.websites = [Website(profile.website!)];
    }

    await contact.insert();
    messenger.showSnackBar(
      const SnackBar(content: Text('Saved to your contacts ✓')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Couldn\'t save contact: $e')),
    );
  }
}
