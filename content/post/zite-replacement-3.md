---
title: Building a Zite Replacement (Part 3)
date: 2015-09-20T08:12:00
author: Graham Wheeler
category: Programming
comments: enabled
---


Since [yesterdays post on term extraction](http://www.grahamwheeler.com/posts/zite-replacement-2.html), I've made a few tweaks. In particular I only adjust capitalization on the first words of sentences, I'm keeping numbers and hyphenation, and if there are consecutive capitalized words I turn them into single terms.

For example, the terms for the Donald Trump on vaccines article have changed from:
<!-- TEASER_END -->

    vaccines
    Donald
    Trump
    children
    doses
    effective
    vaccinations
    diseases
    Carson
    debate

to:

    vaccines
    children
    Donald Trump
    doses
    effective
    vaccinations
    diseases
    smaller
    vaccination
    debate
    babies
    autism
    cause
    schedule
    studies

I'm not sure why 'Carson' was dropped; it's possible that the text of the article changed between the two runs. This shows too that it may be good to deal with plural forms (so 'vaccination' covers 'vaccinations'); on the other hand, having three forms of vaccine appear certainly does strengthen the topic. There is certainly some more tweaking to do but overall I'm pretty happy.

The next step is classification. I was disappointed to find that the category element is rarely used in RSS (so far I haven't seen it). That is going to make using [supervised learning](https://en.wikipedia.org/wiki/Supervised_learning) (where I have a set of training documents with known categories) quite tricky. Fortunately, [unsupervised learning](https://en.wikipedia.org/wiki/Unsupervised_learning) can help a lot here! In unsupervised learning you just throw a bunch of data at a learning algorithm and it does useful things like [clustering](https://en.wikipedia.org/wiki/Cluster_analysis) for you. Essentially this means I can use an algorithm like [k-means](https://en.wikipedia.org/wiki/K-means_clustering) to group similar articles together. I can then go through those by hand and tag them much faster with categories, and then once they are tagged I can go back to using supervised learning.

*k-means* is just one (very common) algorithm for unsupervised learning. There are some other interesting algorithms for topic extraction that may help here too. In the document classification field, a particularly promising one is [latent Dirichlet allocation](https://en.wikipedia.org/wiki/Latent_Dirichlet_allocation),  which is a form of [latent semantic analysis](https://en.wikipedia.org/wiki/Latent_semantic_analysis). It's fairly easy to implement but there is a great Python library for this ([gensim](https://radimrehurek.com/gensim/)) that I will explore. But I am getting ahead of myself, because first I need a corpus of documents, and perhaps you can help!

In order to get my corpus, I need to gather a large number of URLs for RSS feeds. I have a list of about 40 tech feeds I used to follow back in the days when Google Reader was a thing. I've also pulled all the URLs out of my Pocket booksmarks - over 3000 - but these are article links, not feed URLs. So I am going to write a script that takes a bunch of article links and scrapes the pages to try find RSS feed URLs. Unfortunately, my interests are very skewed toward tech, with a bit of cooking, math and fitness thrown in. If you have collections of URLs or RSS feeds covering other topics I would be very happy to add them to my collection.

A first cut at such a script is:


    #!python
    def get_feed_URL(site):
        f = urllib.urlopen(site)
        content = f.read()
        m = re.search("<link[^>]*application/rss\+xml[^>]*href=[\"']([^\"']+)[\"']", content)
        if not m:
            m = re.search("<a [^>]*class=\"rss\"[^>]*href=[\"']([^\"']+)[\"']", content)
        if not m:
            m = re.search("<a [^>]*href=[\"']([^\"']+)[\"'][^>]*class=\"rss\"", content)        
        if m:
            feed = m.group(1)
            if feed[0] == '/':
                feed = site + feed
            return feed
        return None


I'll post any updates later. If possible I may try write one that can be run against Pocket, and try get people to use that to send me already curated lists with possible tags. Watch this space.

*Update:* Gotta love Python. A web search gave me [feedfinder](http://www.aaronsw.com/2002/feedfinder/feedfinder.py).

