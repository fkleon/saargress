import 'package:saargress_app/saargress_api.dart' show TOAccessCredential;
import 'package:polymer/polymer.dart';

/**
 * A Polymer google-signin-aware element.
 */
@CustomTag('google-signin-aware')
class GoogleSigninAware extends PolymerElement {

  /// The scopes to provide access to (e.g https://www.googleapis.com/auth/drive)
  /// and should be space-delimited.
  @published String scopes = '';

  /// Constructor used to create instance of GoogleSigninAware.
  GoogleSigninAware.created() : super.created();

  void authSuccess(e, detail, sender) {
    if(detail == null) {
      print('(google-signin-aware) Illegal message, null detail.');
      return;
    }
    // Check if correct scopes authorized, if not do nothing and continue to wait
    var complete = false;

    var authorizedScopes = detail['scopes'];
    var tokenData = detail['tokenData'];
    var credentials = new TOAccessCredential.fromJson(detail['credentials']);

    if(authorizedScopes != null) {
      var neededScopes = this.scopes.split(' ');
      complete = true;
      for(var scope in neededScopes) {
        if(scope != '' && !authorizedScopes.contains(scope)) {
          complete = false;
          break;
        }
      }
    }

    if(complete) {
      print('(google-signin-aware) All ready!');
      this.fire('google-signin-aware-success', detail: credentials);
    } else {
      print('(google-signin-aware) Missing scopes!');
    }
  }

  /// Called when an instance of google-signin-aware is inserted into the DOM.
  attached() {
    super.attached();

    // Request auth
    this.fire('core-signal', detail: {
        'name': 'google-auth-request',
        'data': this.scopes
      });
  }
}
