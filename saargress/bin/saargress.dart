import 'package:logging/logging.dart';

import 'package:saargress/saargress_server.dart' as saargress;

// Server configuration
final HOST = '127.0.0.1'; // eg: localhost
final PORT = 8081;        // port, must match the client program

// Oauth configuration (Google OAuth2)
final CLIENT_ID = '<APPLICATION_CLIENT_ID>.apps.googleusercontent.com';

// Slack configuration
final String SLACK_DB_PATH = '../data';

void main() {
  // Logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((lr) {
    print('${lr.time} ${lr.level} ${lr.message}');
  });

  // Go!
  saargress.start(HOST, PORT, importDir: SLACK_DB_PATH, oAuthClientId: CLIENT_ID);
}