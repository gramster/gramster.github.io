---
title: Easy Architecture Improvements
date: 2007-04-16T05:23:00
author: Graham Wheeler
category: Programming
slug: easy-architecture-improvements
---

I was searching a couple of days back for a tool that would generate
dependency matrices for C\# code. I didn't find free ones, but I did
find a [plugin](http://tcdev.free.fr/) for Lutz Roeder's
[Reflector](http://www.aisto.com/roeder/dotnet/) that will do this for
compiled assemblies, which is just as good. I haven't done a fresh
install of reflector for quite some time and didn't know it supported
add-ins, but it does and there are a few good ones.

The dependency matrix tool is absolutely fantastic, and I highly
recommend it. Amongst other things it will generate a report that
includes cyclic dependencies. Just that is worth its weight in gold.
Cyclic dependencies typically creep in when you make short cut kludges
to hack in some inappropriate type-dependent logic into a class.  As
such, its usually an indication of a design break, and it also makes
unit testing harder. Use this tool, look at any cycles it reports, and
fix them. Your code will be better as a result.
