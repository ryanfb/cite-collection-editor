CITE Collection Editor
======================

Overview
--------

This is a client-side JavaScript editor for CITE collections stored in Google Fusion Tables.

Configuration
-------------

* Get a Google Fusion Tables API key:
  * Visit the [Google APIs Console](https://code.google.com/apis/console) (you may need to sign up and create an initial project)
 * Go to the 'Services' tab and enable the Fusion Tables API
 * Go to the 'API Access' tab and create a client ID
* Set the redirect URI to the HTML endpoint the JavaScript will be called from
* Set 'JavaScript origins' to the domain the JavaScript will be hosted on
* Copy the client ID into `[TODO: split out configuration parameters]`
* Compile CoffeeScript to JavaScript (now available from Gradle build)
