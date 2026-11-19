import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Only the public course material endpoint is eligible for offline copies.
class OfflineMaterials {
  static final _public = RegExp(r'^/materials/([1-9][0-9]{0,17})/pdf$');
  static String? idFor(String path) => _public.firstMatch(path)?.group(1);
  static Future<Directory> _folder() async =>
    Directory('${(await getApplicationSupportDirectory()).path}/nu-public-materials');

  static Future<File?> find(String path) async {
    final id = idFor(path);
    if (id == null) return null;
    final file = File('${(await _folder()).path}/$id.pdf');
    return await file.exists() ? file : null;
  }

  static Future<void> save(String path, String title, Uint8List bytes) async {
    final id = idFor(path);
    if (id == null || bytes.length < 5 || bytes.length > 50000000 ||
        ascii.decode(bytes.sublist(0, 5), allowInvalid: true) != '%PDF-') {
      throw const FormatException('This document cannot be saved offline.');
    }
    final folder = await _folder();
    await folder.create(recursive: true);
    final pdf = File('${folder.path}/$id.pdf');
    final index = File('${folder.path}/$id.json');
    final files = await list();
    final totals = files.where((item) => item.id != id).fold<int>(0,(total,item)=>total+item.size);
    if (totals + bytes.length > 250000000) {
      throw const FileSystemException('Remove an offline document to make room.');
    }
    final temp = await folder.createTemp('saving-');
    try {
      final contents = await File('${temp.path}/file.pdf').writeAsBytes(bytes,flush:true);
      final meta = await File('${temp.path}/file.json').writeAsString(jsonEncode({'title':title}),flush:true);
      await contents.rename(pdf.path);
      await meta.rename(index.path);
    } finally {
      await temp.delete(recursive:true);
    }
  }

  static Future<List<OfflineMaterial>> list() async {
    final folder = await _folder();
    if (!await folder.exists()) return [];
    final items = <OfflineMaterial>[];
    await for (final entity in folder.list(followLinks:false)) {
      final name=entity.uri.pathSegments.last;
      final id = RegExp(r'^([1-9][0-9]{0,17})\.pdf$').firstMatch(name)?.group(1);
      if (entity is! File || id==null) continue;
      var title='Course material #$id';
      try {
        final metadata=File('${folder.path}/$id.json');
        if(await metadata.exists()){
          final parsed=jsonDecode(await metadata.readAsString());
          if(parsed is Map&&parsed['title'] is String)title=parsed['title'] as String;
        }
      }catch(_){ /* The file remains accessible without optional metadata. */ }
      items.add(OfflineMaterial(id,title,await entity.length()));
    }
    items.sort((a,b)=>a.title.compareTo(b.title));
    return items;
  }

  static Future<void> remove(OfflineMaterial item) async {
    if(idFor(item.path)!=item.id)throw const FormatException('Invalid material');
    final folder=await _folder();
    for(final ext in ['pdf','json']){
      final file=File('${folder.path}/${item.id}.$ext');
      if(await file.exists())await file.delete();
    }
  }
}

class OfflineMaterial {
  const OfflineMaterial(this.id,this.title,this.size);
  final String id,title;
  final int size;
  String get path=>'/materials/$id/pdf';
}
