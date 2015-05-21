CITE Collection Editor
======================

Overview
--------

This is a client-side JavaScript editor for [CITE collections](http://cite-architecture.github.io/) stored in Google Fusion Tables.

Configuration
-------------

* Get a Google Fusion Tables API key:
  * Visit the [Google APIs Console](https://code.google.com/apis/console) (you may need to sign up and create an initial project)
  * Go to the 'Services' tab and enable the Fusion Tables API
  * Go to the 'API Access' tab and create a client ID
  * Set the redirect URI to the HTML endpoint the JavaScript will be called from
  * Set 'JavaScript origins' to the domain the JavaScript will be hosted on
* Create a Fusion Table with columns for the CITE properties you wish to have in your CITE collection. All columns should have type "Text", except any `datetime` properties which can have type "Date/Time".
* Copy or edit `src/capabilities/testedit-capabilities.xml` to reflect your CITE collection(s) and properties. The `class` attribute of a `<citeCollection>` should be the encrypted Fusion Tables table id. Set the `abbr` property of `<namespaceMapping>` to your CITE namespace abbreviation. URNs in the collection will be of the form `urn:cite:{namespaceMapping.abbr}:{citeCollection.name}`.
* Copy `gradle.properties-dist` to `gradle.properties`, adding your API key and relative capabilities URL

        capabilities_url=capabilities/your-testedit-capabilities.xml
        google_client_id=your_id_here.apps.googleusercontent.com

* Run `gradle build`


## Requirements
- gradle 1.1 required to compile coffeescript to javascript
