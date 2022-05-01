---
title: Why There Is No Integration With Outlook Mobile Contacts
date: 2008-02-01T05:34:00
author: Graham Wheeler
category: Mobile
slug: why-there-is-no-integration-with-outlook-mobile-contacts
---

We often get asked why we don't have a menu item in the Contacts app on
the phone to map a contact, but Google does. The comments can sometimes
be quite disparaging (like what's wrong with you people in Redmond,
anyway?). So here is the tale, told by an idiot, without much sound or
fury.

Early in 2006 I wrote the code to hook into Contacts. It worked pretty
well, and we planned to ship this in our v2 release in July '07. Shortly
before our release date, Google released an update to their Windows
Mobile map app, and they had the feature. So we immediately decided to
test to make sure we played nicely together.
<!-- TEASER_END -->

Unfortunately, we found that if you installed GMM and then installed
Live Search, and then you selected the 'Map in Google Maps' menu option,
instead of GMM starting, Live Search would start. Pretty cool, except
there was no way we could ship like that! Imagine the press we would get
in the blogosphere - people would think we were maliciously taking over
GMM's contact mapping feature.

I spent nearly a week trying to figure out what was going on. In the
end, I found that the code sample from the Windows Mobile SDK that I
based my menu extension DLL on had a bug, and I had cut and paste that
bug into our own code. So I fixed the bug - but we still had the
problem. It quickly became obvious that Google's programmers had done
exactly the same thing, and they had the same bug!

So we put the feature on ice (which everyone agreed was the right thing
to do), and I contacted a friend of mine who works at Google and asked
her to pass on a message to the GMM developers, telling them that they
had this bug and how to fix it. Some time later I got a message back
saying they had fixed the bug in their code, but it was too late for us
to include the feature in the release. Some time in the future we'll
finally release our version.

So let this be a cautionary tale - don't assume code samples you get off
MSDN, in and SDK, or anywhere else for that matter, don't have bugs.
This particular bug only bit if you loaded more than one extension DLL
into Contacts, so the person who wrote the code sample never noticed,
and nor did Google.

I've always wondered though - what would have happened if we had shipped
first?

For those who are interested, the bug was in the return value of
QueryContextMenu. The MSDN sample returns S\_OK, which is not the right
response. Here is the correct documentation from MSDN:

> "If successful, returns an **HRESULT** value that has its severity
> value set to SEVERITY\_SUCCESS and its code value set to the offset of
> the largest command identifier that was assigned, plus one. For
> example, assume that *idCmdFirst* is set to 5 and you add three items
> to the menu with command identifiers of 5, 7, and 8. The return value
> should be MAKE\_HRESULT(SEVERITY\_SUCCESS, 0, 8 - 5 + 1). Otherwise,
> it returns an OLE error value."
