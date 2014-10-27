part of saargress_api;

/// Serializable AccessCredential for use as payload in core events
class TOAccessCredential extends AccessCredentials {

  TOAccessCredential(AccessToken accessToken, String refreshToken, List<String> scopes):
    super(accessToken, refreshToken, scopes);

  TOAccessCredential.fromJson(Map jsonData):
     super(new TOAccessToken.fromJson(jsonData['accessToken']), jsonData['refreshToken'], jsonData['scopes']);

  TOAccessCredential.fromAC(AccessCredentials ac): super(ac.accessToken, ac.refreshToken, ac.scopes);

  Map toJson() => {
    'accessToken': new TOAccessToken.fromAT(super.accessToken).toJson(),
    'refreshToken': super.refreshToken,
    'scopes': super.scopes
  };
}

/// Serializable AccessToken for use as payload in core events
class TOAccessToken extends AccessToken {

  TOAccessToken(String type, String data, DateTime expiry):
    super(type, data, expiry);

  TOAccessToken.fromJson(Map jsonData):
    super(jsonData['type'], jsonData['data'], DateTime.parse(jsonData['expiry']));

  TOAccessToken.fromAT(AccessToken at): super(at.type, at.data, at.expiry);

  Map toJson() => {
    'type': super.type,
    'data': super.data,
    'expiry': super.expiry.toIso8601String()
  };
}

final DateFormat df = new DateFormat('yyyy-MM-dd HH:mm:ss');

/// A slack message
class SlackMessageItem extends Observable {
  bool selected = false;
  final String id;
  final String text, type;
  final String userId;
  final String userName;
  final DateTime ts;

  SlackMessageItem({this.id, this.text, this.type, this.userId, this.userName, this.ts});

  SlackMessageItem.fromJson(Map jsonData):
        this.id = jsonData['id'], this.text = jsonData['text'],
        this.type = jsonData['type'], this.userId = jsonData['user'],
        this.userName = jsonData['userName'],
        this.ts = DateTime.parse(jsonData['ts']);

  get date => df.format(ts);
}

class SlackChannelItem {

  final String name;
  final bool isChannel;

  SlackChannelItem.fromJson(Map jsonData):
    this.name = jsonData['name'],
    this.isChannel = jsonData['is_channel'];
}