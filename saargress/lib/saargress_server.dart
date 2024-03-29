library saargress_server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:option/option.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_route/shelf_route.dart';
import 'package:shelf_auth/shelf_auth.dart';
import 'package:shelf_rest/shelf_rest.dart';
import 'package:shelf_exception_response/exception_response.dart' show BadRequestException,
  NotFoundException, UnauthorizedException, exceptionResponse;

part 'src/middleware.dart';
part 'src/slacklog.dart';
part 'src/auth.dart';
part 'src/rest.dart';

SlackDatabase _slackDB;

/// Starts the Saargress server with the given parameters
void start(String host, int port, String oAuthClientId, {String importDir, bool secure:false}) {
  if(importDir != null) {
    SlackImporter.buildFromDir(importDir).then((sdb) {
        _slackDB = sdb;
        sdb.updateUserNames();
        log.info('Initialized SlackDB: ${_slackDB.toJson()}');
      }).then((_) => _startServer(host, port, oAuthClientId, secure));
  } else {
    _slackDB = new SlackDatabase.empty();
    _startServer(host, port, oAuthClientId, secure);
  }
}

void _startServer(String host, int port, String oAuthClientId, bool secure) {
  // Authentication via GoogleOAuth and Slack User DB
  SlackUserLookup sul = new SlackUserLookup(_slackDB.users);

  var jwtSessionHandler = new JwtSessionHandler('Saargress App', new Uuid().v4(),
          sul.lookupByEmail);

  var authMiddleware = authenticate(
      [new GoogleOAuth2Authenticator(oAuthClientId, sul)],
      sessionHandler: jwtSessionHandler,
      allowAnonymousAccess: false,
      allowHttp: true); //TODO disable allowHttp

  var rootRouter = router()
      ..addAll(bindResource(new SlackLogResource()), path: '/logs')
      ..add("/auth", ["GET"], _authRequest);

  var handler = const shelf.Pipeline()
      .addMiddleware(corsHeaderMiddleware)
      .addMiddleware(shelf.logRequests())
      .addMiddleware(exceptionResponse())
      .addMiddleware(authMiddleware)
      .addHandler(rootRouter.handler);

  if(secure) {
    _initSecureSocket();

    HttpServer.bindSecure(host, port, certificateName: 'CN=dartcert').then((server) {
      shelf_io.serveRequests(server, handler);
      log.info('Using OAuth client ID: $oAuthClientId');
      log.info('Serving at https://${server.address.host}:${server.port}');
    });
  } else {
    shelf_io.serve(handler, host, port).then((server) {
      log.info('Using OAuth client ID: $oAuthClientId');
      log.info('Serving at http://${server.address.host}:${server.port}');
    });
  }
}

void _initSecureSocket() {
  //var testPkcertDatabase = Platform.script.resolve('pkcert')
  //                                   .toFilePath();
  var pkcertDatabase = '/home/freddy/dev/workspaces/dartspace/saargress/saargress/pkcert';
  var pwd = new File(pkcertDatabase+'/pwdfile').readAsStringSync();
  pwd = pwd.substring(0, pwd.length-1);
  SecureSocket.initialize(database: pkcertDatabase,
                          password: pwd);
}

/// Info about auth status
shelf.Response _authRequest(shelf.Request request) {
  Map infoObject = {"auth_success": isAuthenticated(request)};
  return new shelf.Response.ok(JSON.encode(infoObject));
}

/// Info about app and database object
shelf.Response _infoRequest(shelf.Request request) {
  Map infoObject;
  if(isAuthenticated(request)) {
    infoObject = {"name": "Saargress Server",
                        "version": "0.0.1",
                        "user": "${loggedInUsername(request)}",
                        "slackDB": _slackDB};
  } else {
    infoObject = {"name": "Saargress Server",
                        "version": "0.0.1",
                        "user": "${loggedInUsername(request)}",
                        "slackDB": "not authorized"};
  }
  return new shelf.Response.ok(JSON.encode(infoObject));
}

/// Echo request
shelf.Response _echoRequest(shelf.Request request) {
  return new shelf.Response.ok('Request for "${request.url}" by "${getAuthenticatedContext(request).map((ac) => ac.principal.name)}"');
}

bool isAuthenticated(shelf.Request request) => getAuthenticatedContext(request).map((ac) => true).getOrElse(() => false);

String loggedInUsername(shelf.Request request) =>
    getAuthenticatedContext(request).map((ac) => ac.principal.name)
              .getOrElse(() => 'guest');
