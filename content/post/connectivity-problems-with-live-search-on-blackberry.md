---
title: Connectivity problems with Live Search on Blackberry
date: 2008-02-24T05:33:00
author: Graham Wheeler
category: Mobile
slug: connectivity-problems-with-live-search-on-blackberry
---

I just wanted to share this information that one of our Blackberry devs,
Didier, sent to a customer who was having problems as it may be useful
to others:

> Since Live Search for BlackBerry is distributed as an independent
> third party application, it works only if such applications are
> allowed to do network requests, which may depend on both your carrier
> network policies and your subscription type.
>
> We support three connection modes in Live Search for BlackBerry:
> Direct HTTP, BES/MDS and WAP Gateway, but for CDMA devices only Direct
> HTTP and BES/MDS are possible (WAP is specific to GPRS/Edge carriers).
> BES/MDS is for corporate devices administrated through the company’s
> BlackBerry Enterprise Server, Direct HTTP is for individual
> subscribers. You can try both modes if you are unsure of your
> configuration (in Options \> Enter your network configuration
> parameters).
>
> But some BlackBerry data plans may be limited to Email & Web browsing
> and Live Search will not work in this case.
