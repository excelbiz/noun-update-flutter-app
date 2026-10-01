import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Offline-first Study progress for one account/course pair.
///
/// Completed units can be merged safely. Notes are deliberately conservative:
/// when both this device and another device changed non-empty notes, neither
/// version is overwritten until the student explicitly chooses one.
class StudyStateStore {
  StudyStateStore({
    required this.api,
    required this.courseCode,
    this.userId,
  });

  final ApiClient api;
  final String courseCode;
  final String? userId;

  Set<int> done = <int>{};
  String notes = '';
  int revision = 0;
  bool dirty = false;
  String? conflictNotes;
  Object? lastSyncError;

  bool get signedIn => userId != null && userId!.trim().isNotEmpty;
  bool get hasConflict => conflictNotes != null;
  bool get syncPending => signedIn && dirty;
  String get slot => 'nu-study-${userId ?? 'guest'}-${courseCode.replaceAll(' ', '').toUpperCase()}';

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      Map<String, dynamic>.from(response['data'] as Map);

  Future<void> load() async {
    await _loadLocal();
    if (!signedIn) return;
    try {
      final remote = await _fetchRemote();
      if (!dirty) {
        _applyRemote(remote);
        await _persist();
        return;
      }
      await _reconcile(remote, allowPush: true);
    } catch (e) {
      lastSyncError = e;
      // Keep the local copy. A later load/save will retry.
    }
  }

  Future<void> save(Set<int> nextDone, String nextNotes) async {
    done = Set<int>.from(nextDone);
    notes = nextNotes;
    conflictNotes = null;
    lastSyncError = null;
    dirty = signedIn;
    await _persist();
    if (!signedIn) return;
    try {
      await _push();
    } on ApiException catch (e) {
      if (e.code == 'STUDY_STATE_CONFLICT') {
        try {
          await _reconcile(await _fetchRemote(), allowPush: true);
        } catch (inner) {
          lastSyncError = inner;
          dirty = true;
          await _persist();
        }
      } else {
        lastSyncError = e;
        dirty = true;
        await _persist();
      }
    } catch (e) {
      lastSyncError = e;
      dirty = true;
      await _persist();
    }
  }

  Future<void> keepLocalNotes() async {
    if (!hasConflict) return;
    conflictNotes = null;
    dirty = true;
    await _persist();
    try {
      await _push();
    } on ApiException catch (e) {
      if (e.code == 'STUDY_STATE_CONFLICT') {
        await _reconcile(await _fetchRemote(), allowPush: false);
      } else {
        lastSyncError = e;
      }
    } catch (e) {
      lastSyncError = e;
    }
    await _persist();
  }

  Future<void> useRemoteNotes() async {
    final remote = conflictNotes;
    if (remote == null) return;
    notes = remote;
    conflictNotes = null;
    dirty = true; // merged completed units may still need uploading.
    await _persist();
    try {
      await _push();
    } on ApiException catch (e) {
      if (e.code == 'STUDY_STATE_CONFLICT') {
        await _reconcile(await _fetchRemote(), allowPush: false);
      } else {
        lastSyncError = e;
      }
    } catch (e) {
      lastSyncError = e;
    }
    await _persist();
  }

  Future<void> _loadLocal() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(slot);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      done = (decoded['done'] as List? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toSet();
      notes = decoded['notes'] is String ? decoded['notes'] as String : '';
      revision = (decoded['revision'] as num?)?.toInt() ?? 0;
      dirty = decoded['dirty'] == true;
      conflictNotes = decoded['conflict_notes'] is String
          ? decoded['conflict_notes'] as String
          : null;
    } catch (_) {
      done = <int>{};
      notes = '';
      revision = 0;
      dirty = false;
      conflictNotes = null;
    }
  }

  Future<Map<String, dynamic>> _fetchRemote() async => _data(
        await api.getJson(
          '/study/${courseCode.replaceAll(' ', '').toUpperCase()}/state',
        ),
      );

  Future<void> _push() async {
    final result = _data(await api.postJson(
      '/study/${courseCode.replaceAll(' ', '').toUpperCase()}/state',
      {
        'done': (done.toList()..sort()),
        'notes': notes,
        'base_revision': revision,
      },
    ));
    _applyRemote(result);
    lastSyncError = null;
    await _persist();
  }

  Future<void> _reconcile(
    Map<String, dynamic> remote, {
    required bool allowPush,
  }) async {
    final remoteDone = (remote['done'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();
    final remoteNotes = remote['notes'] is String ? remote['notes'] as String : '';
    final remoteRevision = (remote['revision'] as num?)?.toInt() ?? 0;
    final mergedDone = <int>{...done, ...remoteDone};
    final doneChanged = mergedDone.length != remoteDone.length;

    if (revision == remoteRevision) {
      done = mergedDone;
      if (allowPush) {
        await _push();
      } else {
        dirty = true;
        await _persist();
      }
      return;
    }

    done = mergedDone;
    revision = remoteRevision;

    if (notes == remoteNotes) {
      conflictNotes = null;
      if (allowPush && doneChanged) {
        await _push();
      } else {
        dirty = doneChanged;
        await _persist();
      }
      return;
    }

    if (notes.isEmpty) {
      notes = remoteNotes;
      conflictNotes = null;
      if (allowPush && doneChanged) {
        await _push();
      } else {
        dirty = doneChanged;
        await _persist();
      }
      return;
    }

    if (remoteNotes.isEmpty) {
      conflictNotes = null;
      if (allowPush) {
        await _push();
      } else {
        dirty = true;
        await _persist();
      }
      return;
    }

    // Both devices have different non-empty notes. Keep both until the user
    // explicitly resolves which notes should be stored on the account.
    conflictNotes = remoteNotes;
    dirty = true;
    lastSyncError = const ApiException(
      'Your notes changed on another device. Choose which notes to keep.',
      statusCode: 409,
      code: 'STUDY_STATE_CONFLICT',
    );
    await _persist();
  }

  void _applyRemote(Map<String, dynamic> remote) {
    done = (remote['done'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();
    notes = remote['notes'] is String ? remote['notes'] as String : '';
    revision = (remote['revision'] as num?)?.toInt() ?? 0;
    dirty = false;
    conflictNotes = null;
  }

  Future<void> _persist() async {
    final values = done.toList()..sort();
    final ok = await (await SharedPreferences.getInstance()).setString(
      slot,
      jsonEncode({
        'done': values,
        'notes': notes,
        'revision': revision,
        'dirty': dirty,
        if (conflictNotes != null) 'conflict_notes': conflictNotes,
      }),
    );
    if (!ok) throw StateError('Could not save Study progress on this device.');
  }
}
