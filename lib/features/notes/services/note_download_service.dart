import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:matricmate/data/repositories/notes/notes_repository.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:path_provider/path_provider.dart';

class NoteDownloadService {
  static final NoteDownloadService instance = NoteDownloadService._();
  NoteDownloadService._();

  final NotesRepository _repo = NotesRepository();

  /// Gets the local path where this note should be saved.
  Future<String> getNoteLocalPath(int subjectId, int noteId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/notes/$subjectId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/note_$noteId.pdf';
  }

  /// Checks if a downloaded note file exists and is non-empty.
  bool isFileValid(String? localPath) {
    if (localPath == null || localPath.isEmpty) return false;
    final file = File(localPath);
    return file.existsSync() && file.lengthSync() > 0;
  }

  /// Downloads a single note file with real-time progress callback.
  /// Downloads to a `.part` temporary file first, then renames on completion.
  Future<String> downloadNote({
    required NoteModel note,
    required void Function(double progress) onProgress,
  }) async {
    if (note.fileUrl.isEmpty) {
      throw 'Download URL is missing for ${note.title}';
    }

    final targetPath = await getNoteLocalPath(note.subjectId, note.id);
    final tempPath = '$targetPath.part';

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(note.fileUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw 'Failed to download file (HTTP ${response.statusCode})';
      }

      final totalBytes = response.contentLength ?? note.fileSizeBytes;
      int receivedBytes = 0;

      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      await sink.flush();
      await sink.close();

      // Rename temp file to final target file
      final finalFile = File(targetPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(targetPath);

      // Update SQLite record
      await _repo.markNoteDownloaded(note.id, targetPath);

      onProgress(1.0);
      return targetPath;
    } catch (e) {
      // Clean up temp file on failure
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
