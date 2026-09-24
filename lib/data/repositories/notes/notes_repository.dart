import 'dart:io';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesRepository {
  final DatabaseService _dbService = DatabaseService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches notes for a given subject (and optionally a specific grade) from local SQLite.
  Future<List<NoteModel>> getLocalNotes(int subjectId, {int? grade}) async {
    try {
      final db = await _dbService.database;
      String query = 'SELECT * FROM notes WHERE subject_id = ?';
      final List<dynamic> args = [subjectId];

      if (grade != null) {
        query += ' AND grade = ?';
        args.add(grade);
      }

      query += ' ORDER BY chapter_number ASC, order_index ASC';

      final rows = await db.rawQuery(query, args);
      return rows.map((r) => NoteModel.fromMap(r)).toList();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Fetches notes for a specific chapter.
  Future<List<NoteModel>> getNotesByChapter(int chapterId) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'notes',
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
        orderBy: 'order_index ASC',
      );
      return rows.map((r) => NoteModel.fromMap(r)).toList();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Fetches a single note by ID.
  Future<NoteModel?> getNoteById(int noteId) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return NoteModel.fromMap(rows.first);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Fetches remote notes for a subject from Supabase.
  Future<List<Map<String, dynamic>>> fetchRemoteNotes(int subjectId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select()
          .eq('subject_id', subjectId)
          .order('chapter_number', ascending: true)
          .timeout(AppTimeouts.query);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If table doesn't exist yet on remote Supabase, return empty gracefully
      return [];
    }
  }

  /// Calls the Supabase Edge Function `get-note-url` to get a temporary signed URL for R2.
  Future<String> getNoteSignedUrl(int noteId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-note-url',
        body: {'note_id': noteId},
      );

      final data = response.data;
      if (response.status == 200 && data is Map && data['url'] != null) {
        return data['url'].toString();
      }

      final errorMsg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Unable to open this note right now. Please try again.';
      throw errorMsg;
    } on FunctionException catch (e) {
      if (e.status == 401) {
        throw 'You must be logged in to access this note.';
      } else if (e.status == 403) {
        throw 'Premium access is required to view this note.';
      } else if (e.status == 404) {
        throw 'Note or file not found.';
      }
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw details['error'].toString();
      }
      throw 'Unable to open this note right now. Please try again.';
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Saves or updates a batch of notes in SQLite.
  /// Preserves existing `local_file_path` and `is_downloaded` flags.
  /// If remote file_key changed, invalidates stale local copy.
  Future<void> saveNotesBatch(List<Map<String, dynamic>> notesData) async {
    if (notesData.isEmpty) return;
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      for (final raw in notesData) {
        final id = (raw['id'] as num?)?.toInt() ?? 0;
        if (id == 0) continue;

        final map = Map<String, dynamic>.from(raw);
        // Normalize column names
        if (map.containsKey('file_size') && !map.containsKey('file_size_bytes')) {
          map['file_size_bytes'] = map['file_size'];
        }

        final rawKey = map['file_key']?.toString();
        final rawUrl = map['file_url']?.toString();
        final fileKey = (rawKey != null && rawKey.trim().isNotEmpty)
            ? rawKey.trim()
            : (rawUrl?.trim() ?? '');

        // Check if existing record has download status
        final existing = await db.query(
          'notes',
          columns: ['is_downloaded', 'local_file_path', 'downloaded_at', 'file_key'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final oldKey = existing.first['file_key']?.toString();
          final isKeyChanged = oldKey != null &&
              oldKey.isNotEmpty &&
              fileKey.isNotEmpty &&
              oldKey != fileKey;

          if (isKeyChanged) {
            // Remote file changed: delete old local file and invalidate
            final oldPath = existing.first['local_file_path']?.toString();
            if (oldPath != null) {
              final oldFile = File(oldPath);
              if (oldFile.existsSync()) {
                try {
                  oldFile.deleteSync();
                } catch (_) {}
              }
            }
            map['is_downloaded'] = 0;
            map['local_file_path'] = null;
            map['downloaded_at'] = null;
          } else {
            map['is_downloaded'] = existing.first['is_downloaded'];
            map['local_file_path'] = existing.first['local_file_path'];
            map['downloaded_at'] = existing.first['downloaded_at'];
          }
        } else {
          map['is_downloaded'] = 0;
          map['local_file_path'] = null;
          map['downloaded_at'] = null;
        }

        batch.insert(
          'notes',
          {
            'id': id,
            'subject_id': map['subject_id'],
            'chapter_id': map['chapter_id'],
            'grade': map['grade'] ?? 9,
            'chapter_number': map['chapter_number'] ?? 1,
            'title': map['title'] ?? '',
            'description': map['description'],
            'file_key': fileKey,
            'file_url': map['file_url'] ?? fileKey,
            'file_type': map['file_type'] ?? 'pdf',
            'file_size_bytes': map['file_size_bytes'] ?? 0,
            'page_count': map['page_count'] ?? 0,
            'is_premium': (map['is_premium'] == null)
                ? 1
                : (map['is_premium'] == true ||
                        map['is_premium'] == 1 ||
                        map['is_premium'] == '1')
                    ? 1
                    : 0,
            'order_index': map['order_index'] ?? 0,
            'local_file_path': map['local_file_path'],
            'is_downloaded': map['is_downloaded'] ?? 0,
            'downloaded_at': map['downloaded_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Marks a note as downloaded in SQLite.
  Future<void> markNoteDownloaded(int noteId, String localPath) async {
    try {
      final db = await _dbService.database;
      await db.update(
        'notes',
        {
          'is_downloaded': 1,
          'local_file_path': localPath,
          'downloaded_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Removes downloaded file and updates database.
  Future<void> deleteNoteFile(int noteId) async {
    try {
      final note = await getNoteById(noteId);
      if (note != null && note.localFilePath != null) {
        final file = File(note.localFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      final db = await _dbService.database;
      await db.update(
        'notes',
        {
          'is_downloaded': 0,
          'local_file_path': null,
          'downloaded_at': null,
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Deletes all downloaded note files for a subject.
  Future<void> deleteAllDownloadedNotesForSubject(int subjectId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${appDir.path}/notes/$subjectId');
      if (await notesDir.exists()) {
        await notesDir.delete(recursive: true);
      }

      final db = await _dbService.database;
      await db.update(
        'notes',
        {
          'is_downloaded': 0,
          'local_file_path': null,
          'downloaded_at': null,
        },
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
    } catch (_) {}
  }
}
