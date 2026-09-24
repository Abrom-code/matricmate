import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:matricmate/data/repositories/notes/notes_repository.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Token used to cancel active note downloads immediately.
class DownloadCancellationToken {
  bool _isCancelled = false;
  http.Client? _activeClient;

  bool get isCancelled => _isCancelled;

  void attachClient(http.Client client) {
    _activeClient = client;
  }

  void cancel() {
    _isCancelled = true;
    try {
      _activeClient?.close();
    } catch (_) {}
  }
}

class NoteDownloadService {
  static final NoteDownloadService instance = NoteDownloadService._();
  NoteDownloadService._();

  final NotesRepository _repo = NotesRepository();

  /// Sanitizes a file name derived from the R2 object key to prevent directory traversal.
  String sanitizeFileName(String key) {
    var clean = key.split('/').last.split(r'\').last.trim();
    clean = clean.replaceAll(RegExp(r'[^\w\.-]'), '_');
    return clean;
  }

  /// Gets the local path where this note should be saved permanently.
  Future<String> getNoteLocalPath(NoteModel note) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/notes/${note.subjectId}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    var filename = sanitizeFileName(note.fileKey);
    if (filename.isEmpty || !filename.toLowerCase().endsWith('.pdf')) {
      filename = 'note_${note.id}.pdf';
    }
    return '${dir.path}/$filename';
  }

  /// Checks if a downloaded note file exists and is non-empty.
  bool isFileValid(String? localPath) {
    if (localPath == null || localPath.isEmpty) return false;
    final file = File(localPath);
    return file.existsSync() && file.lengthSync() > 0;
  }

  /// Downloads a note file using a temporary signed URL from Cloudflare R2.
  /// Downloads to a `.part` temporary file first, validates integrity, then saves permanently.
  Future<String> downloadNote({
    required NoteModel note,
    required void Function(double progress) onProgress,
    DownloadCancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled == true) {
      throw 'Download cancelled';
    }

    // 1. Request temporary presigned URL from Supabase Edge Function
    final signedUrl = await _repo.getNoteSignedUrl(note.id);

    final targetPath = await getNoteLocalPath(note);
    final tempPath = '$targetPath.part';

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    if (cancellationToken?.isCancelled == true) {
      throw 'Download cancelled';
    }

    final client = http.Client();
    cancellationToken?.attachClient(client);

    try {
      final request = http.Request('GET', Uri.parse(signedUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw 'Failed to download file (HTTP ${response.statusCode})';
      }

      final totalBytes = response.contentLength ?? note.fileSizeBytes;
      int receivedBytes = 0;

      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        if (cancellationToken?.isCancelled == true) {
          try {
            await sink.close();
          } catch (_) {}
          throw 'Download cancelled';
        }

        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      await sink.flush();
      await sink.close();

      if (cancellationToken?.isCancelled == true) {
        throw 'Download cancelled';
      }

      // Verify file integrity
      if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
        throw 'Downloaded note file is empty or incomplete';
      }

      // Rename temp file to final target file
      final finalFile = File(targetPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(targetPath);

      // Verify target file exists and is not empty
      if (!finalFile.existsSync() || finalFile.lengthSync() == 0) {
        throw 'Failed to finalize downloaded note file';
      }

      // Update SQLite record
      await _repo.markNoteDownloaded(note.id, targetPath);

      onProgress(1.0);
      return targetPath;
    } catch (e) {
      // Clean up temp file on failure or cancellation
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      if (cancellationToken?.isCancelled == true ||
          e.toString().toLowerCase().contains('cancelled')) {
        throw 'Download cancelled';
      }

      throw AppExceptionHandler.handle(e);
    } finally {
      client.close();
    }
  }

  /// Fetches a temporary signed URL and caches the PDF to a temporary directory
  /// for immediate online viewing without marking the note as downloaded in SQLite.
  Future<String> cacheNoteForViewing({
    required NoteModel note,
    void Function(double progress)? onProgress,
  }) async {
    // If permanent local file already exists, return it immediately (offline first)
    if (note.isDownloaded && isFileValid(note.localFilePath)) {
      return note.localFilePath!;
    }

    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/notes_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    var filename = sanitizeFileName(note.fileKey);
    if (filename.isEmpty || !filename.toLowerCase().endsWith('.pdf')) {
      filename = 'temp_note_${note.id}.pdf';
    }
    final targetPath = '${cacheDir.path}/$filename';
    final targetFile = File(targetPath);

    // Reuse existing valid cached file if available
    if (await targetFile.exists() && targetFile.lengthSync() > 0) {
      return targetPath;
    }

    // Request temporary signed URL
    final signedUrl = await _repo.getNoteSignedUrl(note.id);

    final tempPath = '$targetPath.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(signedUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw 'Failed to load PDF (HTTP ${response.statusCode})';
      }

      final totalBytes = response.contentLength ?? note.fileSizeBytes;
      int receivedBytes = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }
      }

      await sink.flush();
      await sink.close();

      if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
        throw 'Loaded PDF was empty or incomplete';
      }

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetPath);
      return targetPath;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      throw AppExceptionHandler.handle(e);
    } finally {
      client.close();
    }
  }

  /// Deletes downloaded file from device.
  Future<void> deleteNoteFile(int noteId) async {
    await _repo.deleteNoteFile(noteId);
  }
}
