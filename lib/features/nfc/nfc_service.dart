import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NfcUnavailableException implements Exception {
  final String message;
  NfcUnavailableException(this.message);
  @override
  String toString() => message;
}

class NfcWriteException implements Exception {
  final String message;
  NfcWriteException(this.message);
  @override
  String toString() => message;
}

class NfcService {
  static const _pollingOptions = {
    NfcPollingOption.iso14443,
    NfcPollingOption.iso15693,
  };

  /// Writes a single NDEF URI record pointing at the card's public URL,
  /// e.g. https://nammainfo.com/c/<card-uuid>. This is what phones without
  /// the app installed will open in a browser when they tap the card —
  /// the landing page then offers the app as a secondary option.
  Future<void> writeCardUri(String url) async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      throw NfcUnavailableException(
        'NFC isn\'t available on this device. Make sure NFC is turned on '
        'in Settings.',
      );
    }

    final completer = Completer<void>();

    await NfcManager.instance.startSession(
      pollingOptions: _pollingOptions,
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            throw NfcWriteException('This tag doesn\'t support NDEF.');
          }
          if (!ndef.isWritable) {
            throw NfcWriteException('This tag is read-only or locked.');
          }

          final message = NdefMessage([
            NdefRecord.createUri(Uri.parse(url)),
          ]);

          if (message.byteLength > ndef.maxSize) {
            throw NfcWriteException('This tag is too small for this link.');
          }

          await ndef.write(message);
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );

    return completer.future;
  }

  /// Listens for a tapped card while the app is in the foreground and
  /// returns the URL encoded on it (or null if it wasn't a recognizable
  /// URI record). Cancel with [stop] on screen dispose.
  Future<String?> readOnce() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      throw NfcUnavailableException('NFC isn\'t available on this device.');
    }

    final completer = Completer<String?>();

    await NfcManager.instance.startSession(
      pollingOptions: _pollingOptions,
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          final message = ndef?.cachedMessage ?? await ndef?.read();
          final record = (message != null && message.records.isNotEmpty)
              ? message.records.first
              : null;

          final uri = record != null ? _decodeUriRecord(record.payload) : null;
          if (!completer.isCompleted) completer.complete(uri);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );

    return completer.future;
  }

  Future<void> stop() => NfcManager.instance.stopSession();

  /// Decodes an NFC Forum "URI Record Type Definition" payload: the first
  /// byte is a well-known prefix code, the rest is the remaining URI text.
  String? _decodeUriRecord(List<int> payload) {
    if (payload.isEmpty) return null;
    const prefixes = [
      '', 'http://www.', 'https://www.', 'http://', 'https://',
      'tel:', 'mailto:',
    ];
    final prefixCode = payload.first;
    final prefix = prefixCode < prefixes.length ? prefixes[prefixCode] : '';
    final rest = String.fromCharCodes(payload.skip(1));
    final uri = '$prefix$rest';
    return uri.isEmpty ? null : uri;
  }
}
