---
title: Building a Zite Replacement (Part 10)
date: 2015-11-07T08:30:00
author: Graham Wheeler
category: Programming
comments: enabled
---

I've spent the past few days refining the web server, largely for diagnostic
purposes, so it can replace the old TkInter app. I can seen articles for 
categories or feeds, their rank, and detailed information on why they 
received particular categories and ranks. This has enabled me to improve
the categorization and ranking algorithms. I'm at a point now where I 
feel I need a lot more sources than the ~4000 I have right now, as well as
more categories. The latter is more complex and will take me back to some
of my earlier explorations in clustering, etc. The former largely involves 
mining more of the web to find useful sites.
<!-- TEASER_END -->

Currently doing a pull of the ~4000 sites takes several minutes on my 
low-power server. If I want to scale to 10x or more polling is not ideal.
So another change I have needed is to move to a push model. Thankfully
that's possible, through the use of the [PubSubHubbub](https://en.wikipedia.org/wiki/PubSubHubbub) (aka PuSH). This is a Google-designed 
system whereby publishers can 
push notifications of updates to central servers that in turn support
subscriptions on clients for receiving notifications. There are commercial 
services for this ([Superfeedr](http://superfeedr.com) seem's to be the main
player here) but there is also a publicly accessible server run by Google.

Using this is fairly straightforward. Here is a simple Python script for
subscribing or unsubscribing. You pass in a command (subscribe/unsubscribe), an
RSS feed URL you want notfications for, and a callback URL that the PuSH
server will call back to, both to confirm the subscription and to send
notifications to:

```python
#!python
import sys
import urllib
import urllib2

if __name__ == '__main__':
  if len(sys.argv) != 4:
    print "Usage: python pubsub.py (subscribe|unsubscribe) <feed> <callback>" 
  else:
    params = {
        'hub.mode': sys.argv[1],
        'hub.verify': 'sync',
        'hub.callback': sys.argv[3],
        'hub.topic': sys.argv[2],
    }

    try:
        request = urllib2.Request(
            "https://pubsubhubbub.appspot.com",  # Google server
            data=urllib.urlencode(params))
        urllib2.urlopen(request)
    except Exception as e:
      print '%s failed: %s" % (command, str(e))
```

You can include a verification token too in the params, and your callback
server can verify that to make sure that you did the subscribe request and 
not someone else.

The other part of this is the callback server. In my case I want to just fold
this in to my node server, so I added this code in my routes/index.js file. For
now I'm just writing the updates to a file. My callback URL is hostname/pubsub:

    #!javascript
    router.get('/pubsub', function(req, res) {
      if (req.query['hub.challenge']) {
        // Subscription verification request; send back challenge
        res.send(req.query['hub.challenge']);
      } else {
        // Update notification
        res.send('');
        fs.appendFile('pubsub.txt', JSON.stringify(req.body) + '\n',
          function (err) {
          }
        );
      }
    });

You can find full details of the PuSH spec [here](https://pubsubhubbub.googlecode.com/git/pubsubhubbub-core-0.4.html).

