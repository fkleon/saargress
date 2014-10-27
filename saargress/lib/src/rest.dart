part of saargress_server;

@RestResource('channelName')
class SlackLogResource {
  List<SlackLog> search(String name) {
    List<SlackLog> sl = _slackDB.searchLogByName(name);
    // compact view without messages
    return sl.map((sl) => new SlackLog.build(sl.id, name: sl.name,
        is_channel: sl.is_channel, is_general: sl.is_general,
        creator: sl.creator)).toList();
  }

  SlackLog find(String name) => _slackDB.findLogByName(name);

  Map<dynamic, dynamic> childResources = {
      '/messages' : new SlackMessageResource()
    };
}

@RestResource('messageId')
class SlackMessageResource {
  List<SlackMessage> search(String channelName, String search) {
    SlackLog sl = _slackDB.findLogByName(channelName);
    return sl.searchByText(search);
  }
}