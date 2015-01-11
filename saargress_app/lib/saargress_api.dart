library saargress_api;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:http/browser_client.dart';
import 'package:googleapis_auth/auth_browser.dart' show authenticatedClient, AccessCredentials, AccessToken;
import 'package:googleapis/oauth2/v2.dart' as oauth2;
import 'package:polymer/polymer.dart';
import 'package:intl/intl.dart';

part 'model.dart';


class SaargressAPI extends Observable {

  final String _saargressHost = 'http://localhost:8081'; //TODO https

  String _saargressAuthHeader;
  AccessCredentials _googleAccessCredentials;

  @observable bool isAuthed = false;

  Future authReady(accessCredentials) {
    if(accessCredentials == null) {
      throw 'AccessCredentials cannot be null.';
    }

    _googleAccessCredentials = accessCredentials;

    var client = new BrowserClient();
    var authClient = authenticatedClient(client, accessCredentials);

    var api = new oauth2.Oauth2Api(authClient);
    return api.userinfo.get().then((userInfo) {
        print("(saargress-api) Hello ${userInfo.name} (${userInfo.email})!");

        var gAccessToken = accessCredentials.accessToken.data;
        var gId = userInfo.id;

        return _authUser(gAccessToken, gId).then((authHeader) {
          _saargressAuthHeader = authHeader;
          isAuthed = true;
          });
      }).whenComplete(() {
        authClient.close();
        client.close();
      });
  }

  /// Initially auths the user against the saargress server based on the Google OAuth token.
  /// If auth was successfull, the auth header (with the saargress access token)
  /// is stored for future requests.
  Future<String> _authUser(String userAccessToken, String googleUserId) {
    Map xAuthHeader = _getXAuthHeader(userAccessToken, googleUserId);
    return HttpRequest.request('${_saargressHost}/auth', requestHeaders: xAuthHeader, withCredentials: true).then((req) {
      String _authHeader = req.getResponseHeader('authorization');
      print("(saargress-api) Auth Header: '$_authHeader'");
      return _authHeader;
     });
  }

  /// Constructs the initial custom saargress auth header
  Map _getXAuthHeader(String userAccessToken, String userId) => {
    'X-Saargress-Auth': 'Bearer ${userAccessToken} ${userId}',
  };

  /// Constructs the auth header
  Map _getAuthHeader() => {
    'Authorization': _saargressAuthHeader
  };

  /// Issues an authed request to the given URL
  Future<String> _authedRequest(String url) {
    if(!isAuthed) {
      throw 'Not logged into Saargress!';
    }
    Map authHeader = _getAuthHeader();
    return HttpRequest.request(url, requestHeaders: authHeader, withCredentials: true)
        .then((req) => req.responseText);
  }

  /// Searches for messages
  Future<List> searchMessage(String channel, String searchTerm) {
    return _authedRequest('${_saargressHost}/logs/${channel}/messages?search=${searchTerm}').then((contents) {
          List msgs = JSON.decode(contents);
          return msgs;
        });
  }

  // Searches for logs
  Future<List> searchLog(String channelName) {
    return _authedRequest('${_saargressHost}/logs?name=${channelName}').then((contents) {
          List msgs = JSON.decode(contents);
          return msgs;
        });
  }

}