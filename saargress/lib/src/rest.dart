part of saargress_server;

@RestResource('name')
class SlackLogResource {
  List<SlackLog> search(String name) => _slackDB.searchLogByName(name);

  SlackLog find(String name) => _slackDB.findLogByName(name);

  Map<dynamic, dynamic> childResources = {
      '/messages' : new SlackMessageResource()
    };
}

@RestResource('messageId')
class SlackMessageResource {
  List<SlackMessage> search(String name, String content) {
    SlackLog sl = _slackDB.findLogByName(name);
    return sl.searchByText(content);
  }
}