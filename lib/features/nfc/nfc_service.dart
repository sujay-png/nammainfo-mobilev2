import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';

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

/// NFC Forum "URI Record Type Definition" well-known prefixes — index 0
/// is used when the URL doesn't match any shorter prefix.
const _uriPrefixes = [
  '', 'http://www.', 'https://www.', 'http://', 'https://',
  'tel:', 'mailto:',
];

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
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
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

          final message = NdefMessage(records: [_encodeUriRecord(url)]);

          if (message.byteLength > ndef.maxSize) {
            throw NfcWriteException('This tag is too small for this link.');
          }

          await ndef.write(message: message);
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
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
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

  /// Encodes a URL as an NFC Forum "URI Record Type Definition" record:
  /// the first payload byte is a well-known prefix code, the rest is the
  /// remaining URI text (UTF-8). Built by hand against `ndef_record`'s
  /// generic `NdefRecord` constructor — nfc_manager 4.x moved
  /// NdefMessage/NdefRecord into that separate package and dropped the
  /// old `NdefRecord.createUri` convenience factory.
  NdefRecord _encodeUriRecord(String url) {
    var prefixCode = 0;
    var rest = url;
    // Check longer/more specific prefixes first (e.g. "https://www."
    // before "https://").
    for (var i = _uriPrefixes.length - 1; i > 0; i--) {
      if (url.startsWith(_uriPrefixes[i])) {
        prefixCode = i;
        rest = url.substring(_uriPrefixes[i].length);
        break;
      }
    }
    final payload = Uint8List.fromList([prefixCode, ...utf8.encode(rest)]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]), // 'U' — NFC Forum URI record type
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Decodes an NFC Forum "URI Record Type Definition" payload: the first
  /// byte is a well-known prefix code, the rest is the remaining URI text.
  String? _decodeUriRecord(Uint8List payload) {
    if (payload.isEmpty) return null;
    final prefixCode = payload.first;
    final prefix = prefixCode < _uriPrefixes.length ? _uriPrefixes[prefixCode] : '';
    final rest = utf8.decode(payload.skip(1).toList(), allowMalformed: true);
    final uri = '$prefix$rest';
    return uri.isEmpty ? null : uri;
  }
}
