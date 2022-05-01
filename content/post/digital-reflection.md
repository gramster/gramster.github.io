---
title: Digital Reflection
date: 2005-02-11T03:57:00
author: Graham Wheeler
category: General
slug: digital-reflection
---

I've been going through old CD-R discs of mine with a view to reburning
them on DVD-R to safe some space and generally clean them up. It's
amazing what I'm finding - things that I had totally forgotten having
written. For example, I found a SNMPv1/v2 MIB compiler and browser that
I wrote back in 1995. Until I saw it I had no recollection that I even
did that! After some reflection it all came back. In May 1995 I started
Open Mind Solutions with two friends from university days. Our plan was
to do work for hire to finance the development of a software product. At
that stage I had quite a bit of experience with SNMP, having recently
implemented RMON while working for Mosaic Software. It seemed that there
was a lack of good network management software, and what was available
was hugely expensive (HP OpenView pretty much had the market). We felt
that we could build a worthy competitor to OpenView based on FreeBSD.
<!-- TEASER_END -->

Our first job was to raise money, and for that I wrote a network-enabled
clone of HP's advmail X400 mail client for Wooltru. HP's client had to
run on the same machine as the server, which didn't scale at all in
large enterprises like Wooltru. IBM had sold Wooltru a RS6000 server and
OpenMail license, but this was just not going to work, and heads were
about to roll. HP wouldn't commit to fixing this, but referred Wooltru
to a British company that did a lot of OpenMail development. They said
it would take at least 9 months and several million pounds to fix
advmail. We told Wooltru we would write them a complete clone of advmail
that worked over TCP/IP in six weeks, for about \$15,000 (yes, we were
naive, at least in our pricing, but this was South Africa, and that
seemed like a lot of money). It took me four weeks (working 16 hour
days, 7 days a week) to deliver an almost bug-free system that Wooltru
used for several years as a mail client for (IIRC) about 50,000 staff.
That still ranks as one of my two greatest programming feats (my partner
Ian thankfully wrote the text for the hypertext help system - which was
a feature unique to our version; HP's didn't have any).

I used the C++ class library I built on top of ncurses for advremote as
the basis for the SNMP browser, which I started working on after
advremote (our name for our client). It took about two weeks to build a
pretty cool (albeit text mode) SNMP browser/manager app. However, IBM
(through whom we had done the Truworths work) then kept me real busy
writing vertical applications for the beverage retail industry for the
next six months, and the SNMP work gathered dust, which is probably why
I have now all but forgotten about it. Because six months later Aztec
Information Management asked us to write a management front-end for the
Firewall Toolkit (fwtk). And when I saw the awful code in fwtk, and
decided to write my own toolkit in C++, we ended up with our eventual
product, the Citadel Firewall, almost by accident. In less than a year
we changed our names from Open Mind Solutions (oms.co.za) to Citadel
Data Systems (cdsec.com), and the rest is history (for me, anyway). CDS
was eventually bought out by CEQURUX Technologies BV; Ian took cash and
went on to do an MBA in France and became a venture capitalist, while I
took shares and stayed on at CEQURUX - who then fell victim to the dot
com bubble burst. This left me near broke at age 37 and resulted in my
move to the USA. Ce'st la vie.

One point of note in my trawling - my CD-R's go back to 1996. The ones
burnt then are largely unreadable now. It seems anything more than one
directory level deep is lost, and a fair bit more beside. Those burnt in
1998 also have problems, although they're mostly okay. Anecdotaly I
would put the lifetime of a CD-R backup now at no more than 5 years. You
have been warned.
