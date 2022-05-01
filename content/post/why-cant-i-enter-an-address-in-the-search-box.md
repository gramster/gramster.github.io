---
title: Why Can't I Enter An Address In The Search Box
date: 2008-01-19T05:36:00
author: Graham Wheeler
category: Mobile
slug: why-cant-i-enter-an-address-in-the-search-box
---

A common source of confusion for our users is the distinction we make
between 'what' and 'where'. We generally search for 'what' (which is the
text you can enter on the main form), centering the results on the
'where' (which is the location shown just below). If you want to change
the location, *or if you want to search for an address*, you need to
click on 'Choose a new location'; you can then enter the address on the
Location screen and click 'Find' (note: the screen shots shown below
come from a test version of the app we run on the desktop; the menus at
the top will be on the bottom on your phone, accessible via the two
softkeys; I just used the desktop version here as it was quicker for
me):
<!-- TEASER_END -->

[![image](/img/address1.jpg)](/img/address1.jpg)

[![image](/img/address2.jpg)](/img/address2.jpg)

[![image](/img/address3.jpg)](/img/address3.jpg)

The app will then try to locate the address you entered, and if
successful will show you the result, after which you should click
'Done':

[![image](/img/address4.jpg)](/img/address4.jpg)

You'll then be back in the main view with the new address shown as your
search location:

[![image](/img/address5.jpg)](/img/address5.jpg)

You can the click on the Map icon to show a map centered on this
address, or do a search (which will be centered on the address), or
click on Directions for directions. There is something odd about
directions, though - we use your set location as the start point instead
of the end point:

[![image](/img/address6.jpg)](/img/address6.jpg)

You can use left or right DPad actions to spin through the location
lists to change this, or, if the shown end point is actually your start
point, you can just do the route and then reverse it:

[![image](/img/address7.jpg)](/img/address7.jpg)

"But why don't you just allow addresses in the search box?", I hear some
of you ask. Well, the white page and yellow page search services that we
consume don't support mixed queries of what and where together, and we
didn't want to try make the app on the phone second guess what you're
trying to do (actually early versions of the app did do this - if the
what/where search failed we would try again treating the what as a
where - but that produced some strange results so we took it out).

The good news is that there are services now that we can use that do
support mixed queries so in some future release we should handle this
much better.
