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

* Copy the client ID into a JavaScript file which sets `cite_collection_editor_config` on the `window` object,
  which you also include from your `index.html` (this could also be done with inline JavaScript):

        window.cite_collection_editor_config = {
          google_client_id: 'your_id_here.apps.googleusercontent.com',
          capabilities_url: 'capabilities/your-testedit-capabilities.xml'
        };

* Compile CoffeeScript to JavaScript (to be rolled into Gradle build)
