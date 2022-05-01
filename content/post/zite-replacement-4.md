---
title: Building a Zite Replacement (Part 4)
date: 2015-09-22T21:01:00
author: Graham Wheeler
category: Programming
comments: enabled
---



Following my [last post](http://www.grahamwheeler.com/posts/zite-replacement-3.html), I started gathering URLs of feeds to use for sample data. First I scraped the links that I had saved in Pocket (a scarily large number). It didn't seem like Pocket had an easy way to export this, so I loaded up Pocket in Chrome, scrolled and scrolled and scrolled until I could scroll no more, then saved the resulting web page once it was done loading. It was pretty easy to then scrape that to get the links. After sorting and uniq-ing those, and running them through [feedfinder](http://www.aaronsw.com/2002/feedfinder/), I had somewhere north of 1000 feeds. However, these were very skewed to my interests and I wanted diversity so I pressed on and scraped a bunch of blog rolls and other link collections covering many other areas. In the end I got about 2,500 feed URLs to start with, in a file named 'feeds.txt'.
<!-- TEASER_END -->

At that point I ran the code below to fetch and categorize the articles.

    #!python
    import datetime
    import json
    
    with open('feeds.txt') as f:
        feeds = f.readlines()
        
    with open('articles.txt', 'w') as f:
        for feed in feeds:
            feed = feed.strip()
            if len(feed) == 0:
                continue
            print feed
            when = datetime.datetime.utcnow()
            articles = get_feed_with_tf_idf(feed)
            print '%d articles processed from feed %s' % (len(articles), feed)
            for article in articles:
                record = {'feed': feed, 
                          'fetched': str(when),
                          'category': article['category'],
                          'link': article['link'], 
                          'date': article['date'],
                          'terms': article['terms'],
                          'title': article['title'],
                          'thumbnail': article['media_thumbnail']
                }
                f.write(json.dumps(record))
                f.write('\n')


It ran surprisingly fast; it actually took a lot longer to find the feed URLs than it did to fetch the articles and do term extraction. A number of sites returned 0 articles and I need to do  prune of those from the feed list as they are probably either dead or uninteresting.

Once that was done I had close to 40,000 articles to work with. A simple approach is to not even bother going further and just use the extracted terms for deciding what articles to show. I could probably get pretty good results this way; for example, where Zite would typically give me about ten articles on Clojure, I already have over 200!  But I'd like to press on and do some clustering and use that for higher-level tagging and eventually supervised learning.

For clustering we need some way of measuring [similarity](https://en.wikipedia.org/wiki/Similarity_measure)
between articles (or conversely, distance). For [categorical data](https://en.wikipedia.org/wiki/Categorical_variable)
(as opposed to quantitative data), like our lists of terms, a simple but highly effective measure is
[Jacard similarity](https://en.wikipedia.org/wiki/Jaccard_index), which is the size of the intersection 
of our list of terms divided by the size of the union. For example, if one document had the terms 'Obama', 'president', 'visit', and the other had the terms 'Trump', 'president', 'campaign', 'Fiorina', then the Jacard similarity of these documents would be 2/6. The Jacard distance is just 1 - the similarity. Some algorithms work with similarities and some with distances so it is useful to know how to compute both. For points in n-dimensional space, for example, distance is usually Euclidean distance (the square root of the sum of the squares of the distances on each axis), while similarity would be 1/distance,  or some other value that increases as distance decreases; we want to avoid division by zero so 1 / (1 + distance) is more common.

Calculating the Jacard similarity of all the pairwise combinations of nearly 40,000 items is no mean feat, and to make this tractable in an interpreted language like Python you have to leverage libraries that have efficient native implementations under the hood very effectively. I found the code below not too bad; it took about 20 minutes on my MacBook Pro:


    #!python
    import itertools
    import numpy
    
    import json
    
    items = []
    
    # Load the articles back in.
    with open('articles.txt') as f:
        # We will add line number info in for easy cross reference.
        linenum = 0
        for line in f.readlines():
            linenum += 1
            try:
                d = json.loads(line.strip())
            except ValueError as ve:
                print "Failed to parse line %d: %s: %s" % (linenum, line, ve)
            # Drop any that have no terms.
            if len(d['terms']) == 0:
                continue
            items.append({'feed': d['feed'], 
                         'line': linenum,
                         'title': d['title'],
                         'terms': set(d['terms'])})


    def jacard_similarity(row1, row2):
        """ Jacard similarity is the size of the intersection divided by the union.
        """
        set1 = row1['terms']
        set2 = row2['terms']
        intersection_len = float(len(set1.intersection(set2)))
        union_len = float(len(set1) + len(set2) - intersection_len)
        
        return intersection_len / union_len
	
    # Compute the pairwise distance matrix. We do the upper triangle.
    similarity_generator = (jacard_similarity(row1, row2) \
        for row1, row2 in itertools.combinations(items, r=2))
    upper_triangle = numpy.fromiter(similarity_generator, dtype=numpy.float64)


This computes the upper triangle, and we would need to make a reflection around the diagonal to complete a square matrix. Note how we leverage Python sets for efficient calculation of union and intersection, and use itertools instead of explicit loops. To complete the matrix we can do this:


    #!python
    import scipy.spatial
    # Expand to a square
    distance_matrix = scipy.spatial.distance.squareform(upper_triangle)


Once we have this matrix we can use it for our clustering. The approach I am interested in trying is [affinity propagation](https://en.wikipedia.org/wiki/Affinity_propagation). The implementation in SciKit can use a precomputed similarity matrix and apparently its a very good algorithm for finding optimal clusters, but it is quadratic so computing clusters will be slow.

The code to compute the clusters is below:

    #!python
    from sklearn.cluster import AffinityPropagation

    af = AffinityPropagation(affinity='precomputed').fit(distance_matrix)

    cluster_centers_indices = af.cluster_centers_indices_
    labels = af.labels_

    n_clusters_ = len(cluster_centers_indices)

    for k in range(n_clusters_):
        print("Cluster %d\n" % k)
        for n in xrange(len(items)):
            if labels[n] == k:
                print(items[n])


Starting with smaller samples, for 1000 articles I got about 160 clusters; for 2000 about 290, and for 3000, 410.
Some of the clusters make sense (e.g. I see some recipes being clustered) but a lot don't. I expect there are three reasons for this: the small sample across diverse topics mean lots of articles have no common terms, possibly I need more terms, the algorithm is running with all defaults and hasn't been tuned, and of course it is possible I have bugs; I have not validated the Jacard values. So I will need to go deeper. Amongst other things I think I should drop any terms that only occur in single documents as they add cost but no benefit; I found that there are only about 20% of the terms that actually occur in two or more documents.

Watch this space!



