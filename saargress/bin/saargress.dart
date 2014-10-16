import 'package:logging/logging.dart';
import 'package:unscripted/unscripted.dart';

import 'package:saargress/saargress_server.dart' as saargress;

// Default server configuration
const DEFAULT_HOST = '127.0.0.1'; // eg: localhost
const DEFAULT_PORT = 8081;        // port, must match the client program

void main(args) => declare(start).execute(args);

@Command(help: 'Starts the Saargress server')
@ArgExample('--port 4040 --slack-dir ~/slack-db sgd7gdsnm.apps.googleusercontent.com', help: 'Starts the server on port 4040 and imports the Slack data from ~/slack-db.')
@ArgExample('sgd7gdsnm.apps.googleusercontent.com', help: 'Starts the server with defaults.')
void start(
  @Positional(help: 'The client ID issued for Google OAuth2, in the form "<client-id>.apps.googleusercontent.com"',
              parser: _validateGoogleOAuth2ClientId)
  String clientId,
  {
    @Option(help: 'The hostname to bind to, e.g. "localhost".')
    String host: DEFAULT_HOST,
    @Option(abbr: 'p',
            help: 'The port to use, e.g. "8080".')
    int port: DEFAULT_PORT,
    @Option(help: 'A directory containing the slack dump to be imported on startup.')
    String slackDir}
  ) {

  // Logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((lr) {
    print('${lr.time} ${lr.level} ${lr.message}');
  });

  // Go!
  saargress.start(host, port, clientId, importDir: slackDir);
}

String _validateGoogleOAuth2ClientId(String clientId) {
  if(clientId == null || !clientId.endsWith('.apps.googleusercontent.com')) {
    throw 'must not be empty and conform to "<client-id>.apps.googleusercontent.com"';
  }
  return clientId;
}