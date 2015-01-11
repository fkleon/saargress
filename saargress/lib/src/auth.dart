part of saargress_server;

/**
 * Holds all admin user objects.
 */
class SlackUserLookup {
  Iterable<SlackUser> _admins;

  SlackUserLookup(List<SlackUser> userList) {
    _admins = userList.where((user) => user.is_admin);
  }

  Future<Option<Principal>> lookupByEmail(String email) {
    Iterable<SlackUser> users = _admins.where((user) => user.email == email);

    if(users == null || users.isEmpty || users.length > 1) {
      log.info('[SlackUserLookup] \'$email\' is not authorized to access Saargress.');
      //return new Future.value(const None());
      throw new UnauthorizedException({"message": "User '$email' not authorized."});
    }

    final SlackUser user = users.first;
    var principalOpt = new Some(new Principal(user.email));
    return new Future.value(principalOpt);
  }
}

/**
 * A token info includes the tokenData, an userId and an email.
 */
class TokenInfo {
  final String tokenData, userId, email;

  TokenInfo(this.tokenData, this.userId, [this.email]);
}

/**
 * Authenticates against Google's OAuth2 API.
 *
 * Requires an authorization header, defaults to schema:
 *
 * "Authorization: Bearer <TOKEN DATA> <GAIA ID>"
 *
 * The authenticator queries Google's tokeninfo API to verify that the given
 * token is intended to be used with the app identified by CLIENT_ID and
 * is owned by the user with the given GAIA id.
 *
 * It then looks up the user from the given SlackUserLookup.
 */
class GoogleOAuth2Authenticator<P extends Principal> extends Authenticator<P> {

  bool sessionCreationAllowed = true;
  bool readsBody = false;

  /// Name of the authentication header
  String authHeaderName;

  String _oAuthClientId;
  SlackUserLookup _userLookup;

  GoogleOAuth2Authenticator(String this._oAuthClientId, SlackUserLookup this._userLookup, {String this.authHeaderName: 'X-Saargress-Auth'});

  @override
  Future<Option<AuthenticatedContext>> authenticate(shelf.Request request) {
    // Always allow OPTIONS
    if(request.method == 'OPTIONS') {
      return new Future.value(new AuthenticatedContext(const None()));
    }

    TokenInfo creds = _extractCredentials(request);
    return _validate(_oAuthClientId, creds.userId, creds.tokenData)
      .then((tokenInfo) => _userLookup.lookupByEmail(tokenInfo.email))
      .then((principalOption) => principalOption.map((principal) => new AuthenticatedContext(principal)));
  }

  /// Extracts the authentication informations from the request header
  TokenInfo _extractCredentials(shelf.Request request) {
    log.fine('[auth] Authenticating: ${request.headers.toString()}');

    String tokenHeaders = request.headers["X-Saargress-Auth"];
    if(tokenHeaders == null || tokenHeaders.isEmpty) {
      log.warning("Error: No authorization header.");
      throw new UnauthorizedException({"message": "No authorization header."});
    } else {
      // Structure of token header should be:
      // Bearer <tokenData> (<userId>)
      final List<String> tokenParts = tokenHeaders.split(" ");

      if(tokenParts.length != 3) {
        log.warning("Invalid header length: ${tokenParts}");
        throw new BadRequestException({"message": "Invalid authorization header."});
      }

      String authType = tokenParts.elementAt(0);

      if(authType == null || authType.toLowerCase() != "bearer") {
        throw new BadRequestException({"message": "Invalid authorization type."});
      }

      String tokenData = tokenParts.elementAt(1);
      String userId = tokenParts.elementAt(2);

      return new TokenInfo(tokenData, userId);
    }
  }

  /// Query whether this token is still valid.
  Future<TokenInfo> _validate(String clientId, String userId, String tokenData) {
    log.fine("[GoogleOAuth2Authenticator] Validating authorization for user '$userId' with tokenData '$tokenData'..");

    //TODO use googleapis.oauth2.v2.tokeninfo()
    String url = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=${tokenData}";

    var completer = new Completer();

    http.get(url).then((response) {
      if (response.statusCode == 200) {
        completer.complete(response.body);
      } else {
        completer.completeError(new StateError(response.body));
      }
    });

    return completer.future.then((json) {
      final Map data = JSON.decode(json);
      /*
       * When verifying a token, it is critical to ensure the audience field in
       * the response exactly matches your client_id registered in the Google
       * Cloud Console. This is the mitigation for the confused deputy issue,
       * and it is absolutely vital to perform this step.
       */
      final validAudience = clientId == data['audience'];
      /*
       * Additionally check user id, so that one user cannot execute requests
       * for another user.
       */
      final validUserId = userId == data['user_id'];

      final String email = data['email'];

      if(!validAudience || !validUserId) {
        log.warning("[GoogleOAuth2Authenticator] Validation failed for user '$userId' with email '$email'!");
        throw new UnauthorizedException({"message": "Authorization failed - invalid token."});
      } else {
        TokenInfo authedInfo = new TokenInfo(tokenData, userId, email);
        log.info("[GoogleOAuth2Authenticator] Validation successful for user '$userId' with email '$email'!");
        return new Future.value(authedInfo);
      }
    });
  }
}