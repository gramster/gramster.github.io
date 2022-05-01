---
title: Changing the order of home screen icons in Live Search for Mobile
date: 2007-12-23T05:38:00
author: Graham Wheeler
category: Mobile
slug: changing-the-order-of-home-screen-icons-in-live-search-for-mobile
---

If you live in an area where there is no traffic coverage, you may not
want to have the Traffic icon taking up precious real estate on your
home screen. There is a way to re-order the icons, although it is not
for the faint of heart. You need to edit the preferences.xml file in the
\\Programs\\Live Search directory.

In this XML file there is a section with tags \<il\>, and within this
are entries with tags \<it\> and \<ip\>. The former stands for "icon
tag" (starting with zero) and the latter for "icon position" (starting
with 1). By changing the \<ip\> values you can re-order the icons.

While I'm at it, you can also remove locations from the recent location
list; these are in elements that start with \<rt\>. A lot of people ask
how to do this. It's worth mentioning though that you don't really need
to do it; unused locations will eventually drop off the list. The list
maintains the 15 most frequent and most recent locations. The number of
questions we get about this does suggest that 15 is overkill and we may
shrink the number down in future.

If you mess things up when editing the preferences.xml file and the app
won't start, just delete the file. The app will create a new clean
preferences file for you when it next runs.
