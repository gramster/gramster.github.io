---
title: .Net async calls may run on the calling thread
date: 2006-08-22T03:52:00
author: Graham Wheeler
category: Programming
slug: net-async-calls-may-run-on-the-calling-thread
---

I got bitten today with a nasty deadlock in my code. It took a while to
unravel as this particular code involves large numbers of threads making
parallel web service requests. I thought I'd share the particular gotcha
that tripped me up.

For performance reasons, all my calls are aynchronous. I have a callback
for reading HTTP response data, which included the following (grossly
simplified here to just show enough to illustrate the problem):

    private void ReadCallBack(IAsyncResult result)
    {
        int bytesRead = response.EndRead(result);
        if (bytesRead > 0)
        {
            HandleData(buffer, bytesRead);
            lock(this)
            {
                // kick off next read
                response.BeginRead(buffer, 0, len, new AsyncCallback(ReadCallBack), this);
            }
        }
    }

It was important to the logic of my program that I *not* hold the lock
when calling HandleData. However, it turns out that if there is already
data available, the call to BeginRead will not queue a callback on a
different thread but will do the callback immediately itself on the same
thread - so the nested call to HandleData will happen within the locked
region!
