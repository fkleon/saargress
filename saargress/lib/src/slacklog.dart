part of saargress_server;

final Logger log = new Logger('slacklog');

/**
 * Slack log of a channel or group.
 */
class SlackLog {
  String id;
  bool is_general, is_channel;
  DateTime created;
  String creator;
  String name;

  final List<SlackMessage> messages = new List();

  SlackLog.build(this.id, {this.name, this.creator, this.is_general, this.is_channel}) {
    this.created = new DateTime.now();
  }

  SlackLog.fromJson(Map jsonData, {String this.id}) {
    this.is_general = jsonData['is_general'];
    this.is_channel = jsonData['is_channel'];
    // created are seconds since 1970-01-01
    int createdMs = jsonData['created'] * 1000;
    this.created = new DateTime.fromMillisecondsSinceEpoch(createdMs);
    this.creator = jsonData['creator'];
    this.name = jsonData['name'];

    for(Map messageMap in jsonData['messages']) {
      messages.add(new SlackMessage.fromJson(messageMap));
    }

    messages.sort((a, b) => a.ts.compareTo(b.ts));
  }

  Map toJson() => {
    'id': id,
    'is_general': is_general,
    'is_channel': is_channel,
    'created': created.toIso8601String(),
    'creator': creator,
    'name': name,
    'messages': messages
  };

  List<SlackMessage> searchByText(String text) => messages.where
      ((msg) => msg.text != null &&
                msg.text.toLowerCase().contains(text.toLowerCase()))
      .toList();

  @override
  String toString() => '''SlackLog(id=$id, name=$name, is_channel=$is_channel,
                          is_general=$is_general, creator=$creator, created=$created,
                          messages=${messages.length})''';
}


/**
 * Slack message of some kind.
 */
class SlackMessage {
  String id;
  String text, type;
  String userId;
  String userName;
  DateTime ts;

  SlackMessage.build(this.id, {this.userId, this.text, this.type: 'message'}) {
    this.ts = new DateTime.now();
  }

  SlackMessage.fromJson(Map jsonData, {String this.id}) {
      this.text = jsonData['text'];
      this.type = jsonData['type'];
      this.userId = jsonData['user'];
      // ts are seconds since 1970-01-01
      double tsMs = double.parse(jsonData['ts'])*1000;
      int ts = tsMs.toInt();
      this.ts = new DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Map toJson() => {
      'id': id,
      'text': text,
      'type': type,
      'user': userId,
      'userName': userName,
      'ts': ts.toIso8601String()
  };

  @override
  String toString() => '''SlackMessage(id=$id, ts=$ts, user=$userId,
                          text=${textPreview()}, type=$type)''';

  /// Preview of the text (10 characters)
  String textPreview() => '${text == null ? '' : text.substring(0, text.length < 10 ? text.length : 10)}..';
}


/**
 * A slack user.
 */
class SlackUser {
  String id, name;
  bool is_admin, is_owner;

  /// From profile
  String email;

  SlackUser.build(this.id, {this.name, this.email});

  SlackUser.fromJson(Map jsonData) {
    this.id = jsonData['id'];
    this.name = jsonData['name'];
    this.is_admin = jsonData['is_admin'] == null ? false : jsonData['is_admin'];
    this.is_owner = jsonData['is_owner'];
    Map profile = jsonData['profile'];
    if(profile != null) {
      this.email = profile['email'];
    }
  }

  Map toJson() => {
      'id': id,
      'name': name,
      'is_admin': is_admin,
      'is_owner': is_owner,
      'email': email
  };

  @override
  String toString() => 'SlackUser(id=$id, name=$name, email=$email)';
}


/**
 * A simple in-memory database for slack log entries.
 */
class SlackDatabase {
  final List<SlackLog> logs = new List();
  final List<SlackUser> users = new List();

  SlackDatabase.empty();

  /// Initializes the slack log database from the given paths, asynchronously.
  ///
  /// The root dir should be structured as follows:
  /// ./users.json
  /// ./files.json
  /// ./channels/*.json
  /// ./groups/*.json
  /// ./files/*.*
  ///
  @deprecated
  static Future<SlackDatabase> buildFromDir(String rootDirPath) {
    return SlackImporter.buildFromDir(rootDirPath);
  }

  /// Adds the given slack log to the database
  addLog(SlackLog sl) => logs.add(sl);

  /// Adds the given slack user to the database
  addUser(SlackUser su) => users.add(su);

  void updateUserNames() {
    for(SlackLog log in logs) {
      for(SlackMessage message in log.messages) {
        if(message.userName == null) {
          Iterable<SlackUser> matchingUsers = users.where((user) => user.id == message.userId);
          if(matchingUsers.isEmpty) {
            message.userName = 'Unknown (${message.userId})';
          } else {
            message.userName = matchingUsers.first.name;
          }
        }
      }
    }
  }

  /// Finds a slack log by its id (e.g. channel or group name)
  SlackLog findLogByName(String name) {
    Iterable<SlackLog> foundLogs = logs.where((log) => log.name == name);
    if (foundLogs.isEmpty) {
      throw new NotFoundException({'message': 'No log with name "$name".'});
    } else {
      return foundLogs.first;
    }
  }

  /// Searches for a slack log by name
  List<SlackLog> searchLogByName(String name) {
    return logs.where
        ((log) => log.name != null &&
                 log.name.toLowerCase().contains(name.toLowerCase()))
        .toList();
  }

  /// Finds a slack user by its id
  SlackUser findUserById(String id) {
    Iterable<SlackUser> foundUsers = users.where((user) => user.id == id);
    if (foundUsers.isEmpty) {
      throw new NotFoundException({'message': 'No user with id "$id".'});
    } else {
      return foundUsers.first;
    }
  }

  /// Finds a slack user by their email
  SlackUser findUserByEmail(String email) {
    Iterable<SlackUser> foundUsers = users.where((user) => user.email == email);
    if (foundUsers.isEmpty) {
      throw new NotFoundException({'message': 'No user with email "$email".'});
    } else {
      return foundUsers.first;
    }
  }

  /// Returns the total number of messages in this database
  int _numMessages() {
    int numMessages = 0;
    logs.forEach((log) => numMessages += log.messages.length);
    return numMessages;
  }

  Map toJson() => {
    'numLogFiles': logs.length,
    'numLogEntries': _numMessages(),
    'numUsers': users.length,
  };

  @override
  String toString() => 'SlackDatabase(logs=${logs.length}, users=${users.length})';
}

/**
 * Imports a slack dump into the internal database.
 */
class SlackImporter {

  /// Initializes the slack log database from the given paths, asynchronously.
  ///
  /// The root dir should be structured as follows:
  /// ./users.json
  /// ./files.json
  /// ./channels/*.json
  /// ./groups/*.json
  /// ./files/*.*
  ///
  static Future<SlackDatabase> buildFromDir(String rootDirPath) {
    var logDB = new SlackDatabase.empty();
    Directory rootDir = new Directory(rootDirPath);
    return _readFiles(rootDir, logDB);
  }

  /// Reads the JSON files in the given directory and adds the
  /// contents to the given log database.
  static Future<SlackDatabase> _readFiles(Directory rootDir, SlackDatabase slackDB) {
    var completer = new Completer();
    log.info('Reading files from ${rootDir}..');

    // Collect futures indicating that files have been parsed
    List<Future> fileFutures = new List();

    // List directory contents, recursing into sub-directories,
    // but not following symbolic links.
    rootDir.list(recursive: true, followLinks: false)
      .listen((FileSystemEntity entity) {
        if(!_isJsonFile(entity)) {
          return;
        }

        File file = new File(entity.path);
        Future fileFuture = _readFile(file, slackDB);
        fileFutures.add(fileFuture);
       },
       onError: (e) => completer.completeError(e),
       // Wait on all files to be parsed before completing
       onDone: () => completer.isCompleted ? '' : Future.wait(fileFutures).then((_) => completer.complete(slackDB)));

     return completer.future;
   }

  /// Reads and imports a given file into the given slack DB.
  static Future _readFile(File file, SlackDatabase slackDB) {
    log.finer('Reading file ${file.path}..');
    var completer = new Completer();

    file.readAsString(encoding: UTF8).then((jsonContent) {
      // Users file
      if(file.path.contains('users.json')) {
        List<SlackUser> users = _parseUsersJson(jsonContent);
        log.fine('Successfully read ${users.length} users.');
        users.forEach((user) => slackDB.addUser(user));
        completer.complete();
        return;
      }

      // Channel and group IDs are their file name
      String fileId = basename(file.path).split('.')[0];

      if(file.path.contains('channels') || file.path.contains('groups')) {
        SlackLog sl = _parseLogJson(jsonContent, fileId);
        log.fine('Successfully read channel or group log for "${sl.name}": ${sl}!');
        slackDB.addLog(sl);
        completer.complete();
        return;
      }

      log.info('Unknown file: ${file.path}');
      //completer.completeError('Unknown file: ${file.path}');
      completer.complete();
    });

    return completer.future;
  }

  /// Checks if the given file is a json file
  static bool _isJsonFile(FileSystemEntity entity) {
    if(!FileSystemEntity.isFileSync(entity.path)) {
      log.finer('Skipping ${entity.path} (no file)..');
      return false;
    }

    if(!entity.path.endsWith('.json')) {
      log.finer('Skipping ${entity.path} (no JSON file)..');
      return false;
    }

    return true;
  }

  /// Converts a json string to a slack log
  static SlackLog _parseLogJson(String jsonContent, String logId) {
    var json = JSON.decode(jsonContent);
    return new SlackLog.fromJson(json, id: logId);
  }

  /// Converts a json string to a slack user
  static List<SlackUser> _parseUsersJson(String jsonContent) {
    List<SlackUser> users = new List();
    var json = JSON.decode(jsonContent);
    json.forEach((userId, userJson) {
      SlackUser user = new SlackUser.fromJson(userJson);
      log.fine('Successfully read user "$userId" (${user.name})!');
      users.add(user);
    });
    return users;
  }
}