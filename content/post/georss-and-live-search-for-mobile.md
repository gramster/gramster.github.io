---
title: GeoRSS and Live Search for Mobile
date: 2008-06-06T05:26:00
author: Graham Wheeler
category: Mobile
slug: georss-and-live-search-for-mobile
---

Hopefully by now you all have v3.0 of the Live Search client, and are
enjoying the new features (web search, weather, and collections). I'd
like to talk about collections in this post, but first it is worth
mentioning a couple of changes in this version that are less obvious,
and overcome limitations I have blogged about in the past:

-   we now have Outlook contact integration. From Outlook contacts you
    can select the "Show on Map" menu option to map a contact. Google
    Maps contacts integration is still broken,
    but we can't let that hold us back any longer; we gave them nearly a
    year as well as explicit instructions on what their bug was; if they
    can't get their house in order with all that then too bad for them.
    If you do want to use both GMM and Live Search, then install GMM
    last. Their bug will cause problems with any other software that
    installs menu extensions that is installed after them; if the other
    apps are well-behaved then you can install them before GMM and you
    should be okay.
-   we have put back the ability to enter addresses in the search box.
    We have a better geocoder now on the back end and are more confident
    that you will get the results you want when doing this.

<!-- TEASER_END -->
Okay, on to GeoRSS. This was my pet feature that I originally built in
September 2006 and it finally got shipped (and if you say 'about time!'
then I have the names of the two people who kept trying to kill this to
give to you; go blame them ;-))

[![image](/img/georss-image0.png)](/img/georss-image0.png)

The Collections feature is built around Virtual Earth collections, to
make it easier for people who don't know/care about GeoRSS to use the
feature and get some value out of it. For the more hard-core, you can
enter GeoRSS URLs directly:

[![image](/img/georss-image1.png)](/img/georss-image1.png)

The actual collections/feeds are stored in the application directory in
a file called feeds.xml. You may find it instructive to look at that
file.

The cool thing about the URLs is that they can contain metatokens, which
will expand to location-specific values:

[![image](/img/georss-image2.png)](/img/georss-image2.png)

For example, the URL above:

<http://www.homethinking.com/georss/@StateAbbrev@/@City@>

has two such metatokens, namely @StateAbbrev@ and @City@. These will get
converted into appropriate values based on your search location before
the feed is fetched.

The supported metatokens are:

-   @StateName@ - state name, e.g. "Washington"
-   @StateAbbrev@ - state name abbrevaited form e.g. "WA" (outside the
    USA this will be the same as @StateName@)
-   @City@ - city name
-   @Zip@ - zip or postal code
-   @Location@ - the full text shown in the main view for the current
    location
-   @Latitude@, @Longitude@
-   @StartLocation@, @StartLatitude@, @StartLongitude@, @EndLocation@,
    @EndLatitude@, @EndLongitude@ - similar to @Location@ etc but for
    the start and end points of the last route you calculated. The idea
    being you could pass these up to a transit service to get, for
    example, a bus schedule
-   @MyLatitude@, @MyLongitude@, @MyLocationTime@ - the location and
    time (in UTC) of the last GPS fix

In a later post I'll describe the GeoRSS schema that the client
understands (it is a hybrid of GeoRSS, some Yahoo extensions, some KML
and some OASIS xADR address stuff). For now I'll just mention one
interesting extension, namely pushpinurl, which can point to a .ico
file. This file will be used as the pushpin icon on the map for that
result. This can allow you to make custom pushpins.
