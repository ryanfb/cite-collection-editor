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
* Create a Fusion Table with columns for the CITE properties you wish to have in your CITE collection. All columns should have type "Text", except any `datetime`/`timestamp` properties which can have type "Date/Time".
* Copy or edit `src/capabilities/testedit-capabilities.xml` to reflect your CITE collection(s) and properties. The `class` attribute of a `<citeCollection>` should be the encrypted Fusion Tables table id. Set the `abbr` property of `<namespaceMapping>` to your CITE namespace abbreviation. URNs in the collection will be of the form `urn:cite:{namespaceMapping/@abbr}:{citeCollection/@name}`. The CITE Collection Editor has special handling for a few CITE properties:
  * the `citeProperty` with `@type="citeurn"` and `@name` corresponding to `citeCollection/@canonicalId` will be an automatically generated next-available URN (or URN version)
  * a `citeProperty` with `@type="authuser"` will be automatically populated from a user's Google authentication credentials
  * a `citeProperty` with `@type="timestamp"` will be automatically populated with the current datetime
  * a `citeProperty` with `@type="markdown"` will get Markdown editing/preview via [PageDown](https://code.google.com/p/pagedown/)
* Copy `gradle.properties-dist` to `gradle.properties`, adding your API key and relative capabilities URL

        capabilities_url=capabilities/your-testedit-capabilities.xml
        google_client_id=your_id_here.apps.googleusercontent.com

* Run `gradle build`

## Requirements
- gradle 1.1 required to compile coffeescript to javascript

## Authentication Models

There are a few ways the CITE Collection Editor can be set up to allow editing of Fusion Tables:

* Use Fusion Tables permissions. This is the default, if you're just running the CITE Collection Editor without a [https://github.com/ryanfb/cite-collection-editor/](CITE Collection Manager) proxy. Anyone who wants to edit the collection must be added through the Fusion Tables UI via `File->Share` with edit permissions.
* Use the [https://github.com/ryanfb/cite-collection-editor/](CITE Collection Manager) proxy. This allows anyone with a Google account to add to the collection (via proxied authentication). Users can be managed via the `Blocked` column of the Collection Manager's authentication table. You could also change the default of the `Blocked` column in the Collection Manager to `true` for new users, to require an administrator to whitelist new user requests first before they can add contributions, though I have not tried using this authentication model.

It used to be possible to set permissions for a Fusion Table to "anyone with the link can edit", which would allow you to live on the edge and allow contributions without the need for a proxy, but this has apparently been deprecated by Google.
