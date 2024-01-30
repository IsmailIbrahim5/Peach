import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart' as c;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChatRoomCacheManager extends CacheManager{

  final String chatRoomId;

  ChatRoomCacheManager(this.chatRoomId) : super(
    Config(
      'peach_cache_key',
      fileSystem: ChatRoomFileSystem('chatroom_data/chatroom_$chatRoomId'),
    )
  );

  @override
  Future<File> getSingleFile(String url,
      {String? key, Map<String, String>? headers}) async {
    key ??= url;
    final cacheFile = await getFileFromCache(key);
    if (cacheFile != null && cacheFile.validTill.isAfter(DateTime.now())) {
      return cacheFile.file;
    }
    var ref = FirebaseStorage.instance.ref('chatroom_$chatRoomId').child(url);

    return (await downloadFile(await ref.getDownloadURL(), key: key, authHeaders: headers)).file;
  }
}


class ChatRoomFileSystem implements c.FileSystem {
  final Future<Directory> _fileDir;

  ChatRoomFileSystem(String key) : _fileDir = createDirectory(key);

  static Future<Directory> createDirectory(String key) async {
    var baseDir = await getApplicationCacheDirectory();
    var path = p.join(baseDir.path, key);

    var fs = const LocalFileSystem();
    var directory = fs.directory((path));
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    return (await _fileDir).childFile(name);
  }
}
