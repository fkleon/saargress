saargress
===========

A server and web app for the [Saargress Community][saargress], written in the [Dart programming language][dartlang].  

### Usage Information
#### Dart SDK 1.7.0 and newer
Use pub global to activate and run the application:
```
  pub global activate --source path saargress
  pub global run saargress
```

#### Dart SDK 1.6.0
Use pub install to resolve the dependencies, and then run the application:
```
  cd saargress/
  pub install
  dart bin/saargress.dart
```

### Developer Information
The project consists of two parts:
* The Saargress server library containing the server logic.
* The Saargress web app containing the web logic.

- - -
[saargress]: http://www.saargress.de "Saargress Community"
[dartlang]: http://www.dartlang.org "Dart Language"
