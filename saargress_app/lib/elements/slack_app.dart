import 'package:saargress_app/saargress_api.dart' show SaargressAPI, SlackMessageItem, SlackChannelItem;
import 'package:polymer/polymer.dart';


/**
 * A Polymer saargress-app element.
 */
@CustomTag('slack-app')
class SlackApp extends PolymerElement {

  @observable SaargressAPI sAPI;
  @observable String authMessage;

  @observable String searchChannel;
  @observable String searchTerm = 'test';

  @observable ObservableList channels;

  @observable ObservableList messages;
  @observable String searchMessage = 'No search results.';

  @observable var selection;

  /// Constructor used to create instance of SaargressApp.
  SlackApp.created() : super.created();

  /// Called when saargress-app has been fully prepared (Shadow DOM created,
  /// property observers set up, event listeners attached).
  @override ready() {
    this.channels = new ObservableList();
    this.messages = new ObservableList();
  }

  /// Called on google-signin-aware-success
  signedIn(e, detail, sender) {
    // Detail should be TOAccessCredential
    print('Sign in successfully into saargress: $sender, $detail');
    sAPI = new SaargressAPI()
        ..authReady(detail).then(
            (_) => populateChannels(),
            onError: (e) => _handleError(e));
  }

  /// Called by the search button
  search(e, var detail, target) {
    e.preventDefault();

    sAPI.searchMessage(searchChannel, searchTerm).then((messages) {
      this.messages.clear();
      this.messages.addAll(messages.map((msg) => new SlackMessageItem.fromJson(msg)));
    }, onError: (e) => _handleError(e));
  }

  /// Populates the channels list for the drop-down menu
  void populateChannels() {
    sAPI.searchLog('').then((channels) {
      this.channels.clear();
      this.channels.addAll(channels.map((channel) => channel['name']));
        //new SlackChannelItem.fromJson(channel)));
      this.channels.sort();
      this.searchChannel = this.channels.first;
    }, onError: (e) => _handleError(e));
  }

  /// Prints the error message
  _handleError(e) {
    messages.clear();

    if(e.target != null && e.target.status == 401) {
      authMessage = '${e.target.statusText}: ${e.target.responseText}';
    }

    searchMessage = 'Search failed.';
  }

  /*
   * Optional lifecycle methods - uncomment if needed.
   *

  /// Called when an instance of saargress-app is inserted into the DOM.
  attached() {
    super.attached();
  }

  /// Called when an instance of saargress-app is removed from the DOM.
  detached() {
    super.detached();
  }

  /// Called when an attribute (such as  a class) of an instance of
  /// saargress-app is added, changed, or removed.
  attributeChanged(String name, String oldValue, String newValue) {
  }
  */

}
