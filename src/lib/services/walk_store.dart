import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:wildgids/models/walk_recording.dart';

class WalkArchive {
  const WalkArchive({this.draft, this.saved = const []});
  final WalkRecording? draft;
  final List<WalkRecording> saved;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'draft': draft?.toJson(),
    'saved': saved.map((walk) => walk.toJson()).toList(),
  };
  factory WalkArchive.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported walk archive');
    }
    return WalkArchive(
      draft:
          json['draft'] == null
              ? null
              : WalkRecording.fromJson(json['draft'] as Map<String, dynamic>),
      saved:
          (json['saved'] as List)
              .map(
                (walk) => WalkRecording.fromJson(walk as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

abstract class WalkStore {
  Future<WalkArchive> load(String owner);
  Future<void> save(String owner, WalkArchive archive);
}

class FileWalkStore implements WalkStore {
  FileWalkStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;

  Future<File> _file(String owner) async {
    final directory = Directory('${(await _directory()).path}/walks');
    await directory.create(recursive: true);
    final name = base64Url.encode(utf8.encode(owner));
    return File('${directory.path}/$name.json');
  }

  @override
  Future<WalkArchive> load(String owner) async {
    final file = await _file(owner);
    if (!await file.exists()) return const WalkArchive();
    return WalkArchive.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(String owner, WalkArchive archive) async {
    final file = await _file(owner);
    // Write and flush before atomically replacing the last complete snapshot.
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(archive.toJson()), flush: true);
    await temporary.rename(file.path);
  }
}
