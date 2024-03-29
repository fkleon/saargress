import 'dart:html';
import 'dart:async';
import 'dart:js';

import 'package:saargress_app/saargress_api.dart' show TOAccessCredential;

import 'package:polymer/polymer.dart';

import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:googleapis/oauth2/v2.dart' as oauth2;

/**
 * A Polymer google-signin element.
 */
@CustomTag('google-signin')
class GoogleSignin extends PolymerElement {

  /**
   * Enum button label default values.
   */
  static const Map LabelValue = const {
      'STANDARD': 'Sign in',
      'WIDE': 'Sign in with Google'
  };

  /**
   * Enum width values.
   */
  static const Map WidthValue = const {
      'ICON_ONLY': 'iconOnly',
      'STANDARD': 'standard',
      'WIDE': 'wide'
  };

  /// Labels for the buttons
  @published String labelSignin = '';
  @published String labelSignout = 'Sign out';
  @published String labelAdditional = 'Additional permissions required';

  @published bool autoLogin = false;
  @observable bool signedIn = false;
  @observable bool additionalAuth = false;

  /// A Google Developers clientId reference
  @published String clientId = '';

  /// The scopes to provide access to (e.g https://www.googleapis.com/auth/drive)
  /// and should be space-delimited.
  @published String scopes = oauth2.Oauth2Api.UserinfoProfileScope;

  /// Convenience getter
  get scopesList => scopes.split(' ');

  /// Styling options
  @published String height = 'standard';
  @published String width = 'standard';
  @published String theme = 'dark';

  @observable String errorMessage = '';
  //@observable get hasError => errorMessage.isNotEmpty;

  /// If the user is authed, the access credentials are stored here
  auth.AccessCredentials _creds;

  var defaultHandler;

  /// Constructor used to create instance of GoogleSignin.
  GoogleSignin.created() : super.created();

  /// Called when an instance of google-signin is inserted into the DOM.
  void attached() {
    super.attached();
    if (this.clientId == '') {
      throw "A valid clientId is required to use this element";
    }

    if(defaultHandler == null) {
      defaultHandler = this;
    }

    // If no label supplied use the width to determine label.
    if (this.labelSignin == '') {
      if (this.width == WidthValue['WIDE']) {
        this.labelSignin = LabelValue['WIDE'];
      } else if (this.width == WidthValue['STANDARD']) {
        this.labelSignin = LabelValue['STANDARD'];
      }
    }

    if(autoLogin) {
      Element signInBtn = $['signInBtn'];
      _signIn(signInBtn).then((_) => print('(google-signin) Automatically signed in!'));
    }
  }

  /// Called when a google-signin-aware element requests auth for some scopes
  void authRequest(e, scopes, sender) {
    print('(google-signin) $sender requested auth for scopes: ${scopes.split(' ')} [not implemented yet]');
    //_signIn(elem);
    //TODO
  }

  /// Called by the sign in button
  void signIn(Event e, var details, Node target) {
     _signIn(target);
  }

  /// Tries to sign in an user via implicit browser flow:
  ///
  /// Obtains an access credential and fires the google-auth-sucess
  /// event when successful. The event contains an AccessCredentials
  /// object.
  Future<auth.AccessCredentials> _signIn(Element elem) {
    auth.ClientId identifier = new auth.ClientId(clientId, null);
    return accessCredentials(elem, identifier, scopesList).then((credentials) {
          _creds = credentials;

          List<String> authorizedScopes = credentials.scopes; //TODO remove
          print('(google-signin) Authorized for scopes: $authorizedScopes');

          this.asyncFire('core-signal', detail: {
              'name': 'google-auth-success',
              'data': { 'tokenData': credentials.accessToken.data,
                        'scopes': authorizedScopes,
                        'credentials': new TOAccessCredential.fromAC(credentials).toJson()
              }
            });
          //this.fire('google-signin-success', detail: {'result': 'success', 'gapi': client});
          signedIn = true;
          return credentials;
        }, onError: (e) => print('(google-signin) ERROR obtaining access credentials: $e'));
  }

  /// Called by the sign out button:
  /// Revokes the access rights.
  void signOut(Event e, var details, Node target) {
    if(_creds == null) {
      print('(google-signin) User is not signed in.');
      errorMessage = 'User is not signed in.';
      return;
    }

    // Create a jsObject to handle the response.
    context['processData'] = () {
      print('(google-signin) User signed out.');
      this.asyncFire('core-signal', detail: {
        'name': 'google-auth-signed-out',
        'data': { 'tokenData': _creds.accessToken.data,
                  //'credentials': _creds.toString()
                  'credentials': new TOAccessCredential.fromAC(_creds).toJson()
        }
      });
      /*
      this.asyncFire('core-signal', detail: {
          'name': 'google-auth-signed-out',
          'data': {'gapi': _client}
        });
      */
      this.errorMessage = 'User signed out.';
      this.signedIn = false;
    };

    ScriptElement script = new Element.tag("script");
    script.src = "https://accounts.google.com/o/oauth2/revoke?token=${_creds.accessToken.data}&callback=processData";
    document.body.children.add(script);

    /// Fails due to CORS:
    /// XMLHttpRequest cannot load https://accounts.google.com/o/oauth2/revoke?token=.
    /// No 'Access-Control-Allow-Origin' header is present on the requested resource.
    /// Origin 'http://127.0.0.1:8080' is therefore not allowed access.
    /*
    String revokeUrl = 'https://accounts.google.com/o/oauth2/revoke?token=${_creds.accessToken.data}';
    HttpRequest.request(revokeUrl, method: 'GET', requestHeaders: {'Content-Type': 'application/json'}).then((req) {
      if(req.status != 200) {
        print("ERORR");
      }
      print('User signed out: ${req.responseText}');
      this.fire('google-signed-out');
      signedIn = false;
    }, onError: (e) => print(e));
    */
  }

  /// Tries to obtain an authorized client via implicit browser flow
  /// or user consent.
  ///
  /// Deprecated: Use accessCredentials() instead.
  @deprecated
  Future<auth.AuthClient> authorizedClient(Element loginElement, auth.ClientId id, List scopes) {
    return auth.createImplicitBrowserFlow(id, scopes)
       .then((auth.BrowserOAuth2Flow flow) {
     return flow.clientViaUserConsent(immediate: false).catchError((e) {
       print('(google-signin) ERROR authorizedClient(): $e');
       errorMessage = e.toString();
       return loginElement.onClick.first.then((_) {
         return flow.clientViaUserConsent(immediate: true).then((auth.AuthClient client) {
           flow.close();
           return client;
         });
       });
     }, test: (error) => error is auth.UserConsentException);
    });
  }

  /// Tries to obtain access credentials via implicit browser flow
  /// or user consent
  Future<auth.AccessCredentials> accessCredentials(Element loginElement, auth.ClientId id, List scopes) {
    return auth.createImplicitBrowserFlow(id, scopes)
      .then((auth.BrowserOAuth2Flow flow) {
        return flow.obtainAccessCredentialsViaUserConsent(immediate: false).catchError((e) {
          print('(google-signin) ERROR accessCredentials(): $e');
          errorMessage = e.toString();
          return loginElement.onClick.first.then((_) {
            return flow.obtainAccessCredentialsViaUserConsent(immediate: true).then((auth.AccessCredentials creds) {
              flow.close();
              return creds;
            });
          });
        }, test: (error) => error is auth.UserConsentException);
      });
  }

  /*
  /// Called when an instance of google-signin is removed from the DOM.
  detached() {
    super.detached();
  }

  /// Called when an attribute (such as  a class) of an instance of
  /// google-signin is added, changed, or removed.
  attributeChanged(String name, String oldValue, String newValue) {
  }

  /// Called when google-signin has been fully prepared (Shadow DOM created,
  /// property observers set up, event listeners attached).
  ready() {
  }
  */

}
