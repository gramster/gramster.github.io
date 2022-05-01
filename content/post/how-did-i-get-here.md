---
title: How Did I Get Here?
date: 2007-06-02T05:17:00
author: Graham Wheeler
category: Programming
slug: how-did-i-get-here
---

Assertions can be great for detecting unexpected state in your code. But
when a state violation is caught in an assert, the next question is
usually "How did I get here?".

A simple but effective way to track down this kind of issue is the
following: in each class instance allocate a StringBuilder member
(called, for example, stateLog). Then, at each point in the class code
where the state changes, log the change with an appropriate message
(usually a helper method that takes a string message is appropriate
here - it should append the message plus a snapshot of the relevant
member variables to the stateLog). Now, whenever you have an assertion,
you can append stateLog.ToString() to the assertion message.

It's basically like printf debugging where the printfs all get recorded
but don't actually get printed until/unless they become relevant.
Keeping this code in your debug builds is a great defensive technique,
can catch hard to repro bugs, and can save you having to step through
the debugger.
