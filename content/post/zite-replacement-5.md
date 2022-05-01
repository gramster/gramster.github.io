---
title: Building a Zite Replacement (Part 5)
date: 2015-09-23T22:21:00
author: Graham Wheeler
category: Programming
comments: enabled
---


My initial experience with clustering was somewhat disappointing. Its clear I need to do some tuning of the approach. The first thing I did was to rerun the article download process, but instead of just keeping the top ten terms and dropping their TF-IDF values, I kept them all. I think there are better ways to select the terms to use for Jacard similarity.

For starters, using a fixed number of terms could lead to keeping a wildly different range of TF-IDF values for different articles. It makes more sense to have some threshold value and keep all terms that exceed the threshold. That may mean more than ten terms for some articles and less for others.

<!-- TEASER_END -->
Secondly, there is not much point in keeping terms that only appear in a single article. That term may be useful if we search articles based on terms, but it will not help much in computing Jacard distances. Some caution is needed here - dropping these terms does reduce the size of the term set and thus will reduce the union with any other article's term set, thus boosting the similarity that the first article has with all other articles. But as this gets boosted across the board, I don't expect it to be much of an issue.

Finally, it may not be a bad idea to create some 'fake' term sets that can act as cluster centroids. I.e. for some topic, create a term set of terms that are particularly relevant and if possible unique to that topic. Using these as centroids we could simply assign each article to the closest centroid which is a straightforward task. Furthermore, we don't have to compute the $n ^ 2$ matrix of distances; if we have $m$ centroids we need only compute $n \times m$ distances, and if $m$ is fixed we essentially have a linear scaling approach.

In order to do this, it is a reasonable idea to take the full set of terms that occur at least $k$ times for some chosen value $k$, assign each of these terms one or more topics, and then pivot that so each topic has a set of terms, which becomes a pseudo-article and the centroid for that topic.

Below is the code I am now using to get the articles:

    #!python
    import datetime
    import json
    import math
    import operator
    import collections
    from collections import defaultdict
    import feedparser
    import re
    import string 
    import csv
	
    # A simple tag stripper
    from HTMLParser import HTMLParser
	
    class MLStripper(HTMLParser):
        def __init__(self):
            self.reset()
            self.fed = []
        def handle_data(self, d):
            self.fed.append(d)
        def get_data(self):
            return ''.join(self.fed)
    
    def strip_tags(html):
        s = MLStripper()
        s.feed(html)
        return s.get_data()
	
    # Get the word frequencies for top 5000 words
    # You can get this list here: http://www.wordfrequency.info/free.asp
    # I cannot redistribute it so get your own copy to follow along.
	
    words5000 = {}
    total = 0
    count = 0
    top_words = []
    with open('freq5000.csv', 'rb') as f:
        reader = csv.reader(f)
        total = 0
        for row in reader:
            if row[3] == '' or row[3][0] > '9':
                continue
            v = int(row[3])
            word = row[1].encode('ascii', 'ignore')
            count += 1
            if count <= 500:
                top_words.append(word)
            words5000[word] = v
            total += v
    
    total = float(total)
    min_words5000_freq = total
    for word in words5000.keys():
        words5000[word] /= total
        if min_words5000_freq > words5000[word]:
            min_words5000_freq = words5000[word]
    
    def get_article_terms(title, article):
        """
        Get the terms and counts from an article. Strip HTML tags and
        non-essential punctuation, whitespace, and single
        character 'words' like s that may come from punctuation removal.
        Try normalize initial letter case using the 5000 word dictionary.
        Return a set of words and counts and a total count.
        """
        terms = defaultdict(int)
        total = 0
        article = title + '. ' + strip_tags(article)
        # replace non-ASCII chars with space. We keep '-', '.', ',', '\''.
        article = re.sub(r'[^A-Za-z0-9\.,\-\']+',' ', article)
        # replace 's with space and remove other single quotes.
        # We do want to preserve *n't and maybe others so switch those
        # to " and back before/after
        article = string.replace(article, "'s ", " ")\
                        .replace("n't", 'n"t')\
                        .replace("'", ",")\
                        .replace('n"t', "n't")
        # Split on '.' and check first words to see if they should be lower-cased.
        sentences = article.split('.')
        article = ''
        for sentence in sentences:
            words = [w for w in sentence.split(' ') if len(w)]
            if word[0].lower() in words5000:
                word[0] = word[0].lower()
            words.append(',')
            article += ' '.join(words)
            
        # Look for consecutive sequences of capitalized words with no 
        # intervening punctuation other than '-' and turn them into
        # single terms with '_' replacing space.
        sentences = article.split(',')
        article = ''
        for sentence in sentences:
            words = [w for w in sentence.split(' ') if len(w)]
            for i in range(0, len(words) - 1):
                if words[i][0].isupper() and words[i + 1][0].isupper():
                    words[i + 1] = words[i] + '_' + words[i + 1]
                    words[i] = ''
            words.append(' ')
            article += ' '.join(words)                
            
        # replace non-ASCII chars with space. We keep '-' and underscore.
        article = re.sub(r'[^A-Za-z0-9\-_\']+',' ', article)
        # We could use a Counter here but the would need to post-process 
        # the keys to remove the bogus ones and correct capitalization.
        # Consider for later.
        for term in article.split(' '):
            if len(term) < 2 and (term != 'a' or term == 'I'):
                continue
            total += 1
            if term in top_words or \
                (term[0].isupper() and term.lower() in top_words):
                continue
            # Update the count.
               terms[term] += 1
    
        return terms, total
    
    
    def get_article_data(feed_url):
        """
        Calculate the term counts for each article in a feed as well as
        the document counts for each term. Return a list of article 
        metadata including the title, a snippet, the distinct terms and 
        their counts, etc, as well as the counts of how many documents 
        each term appeared in.
        """
        
        d = feedparser.parse(feed_url)
    
        doc_terms = collections.Counter()
        articles = []
    
        entries = d['entries']
        for entry in entries:
            title = entry.get('title', None)
            if title is None:
                continue
            
            # For some sites seem we get summary and some content
            summary = entry.get('summary', None)
            content = entry.get('content', None)
            article = summary if content is None else content
            if article is None:
                continue
            if isinstance(article, list):
                # Maybe concantenate them? Dig into this; it may be 
                # multi-language or something.
                article = article[0]  
            if isinstance(article, dict):
                article = article['value']
        
            terms, count = get_article_terms(title, article)
            doc_terms.update(terms.keys())
            articles.append({'title': title, 
                             'category': entry.get('category', None),
                             'guid': entry.get('guid', None),
                             'terms': terms, 
                             'count': count, 
                             'link': entry.get('link', None),
                             'media_thumbnail': entry.get('media_thumbnail', None),
                             'date': entry.get('published', None)})
        return articles, doc_terms
    
    
    def get_feed_with_tf_idf(feed_url, top_term_count=15):
        """ Calculate TF-IDFs for each article in a feed """
        articles, doc_terms = get_article_data(feed_url)
        for article in articles:
            terms = article['terms']
            tf_idf = {}
            article_count = float(article['count'])
            for term, count in terms.items():
                tf_idf[term] = (count / article_count) * \
                    math.log(len(articles) / float(doc_terms[term]))
            article['tf_idf'] = [{term.replace('_', ' '): weight} \
                for term, weight in tf_idf.items()]
        return articles
     
    # Read the list of feed URLs
    with open('feeds.txt') as f:
        feeds = f.readlines()
        
    # Get the articles for each feed, process them and save them 
    # as JSON to a file.
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
                          'tf_idf': article['tf_idf'],
                          'title': article['title'],
                          'thumbnail': article['media_thumbnail']
                }
                f.write(json.dumps(record))
                f.write('\n')

There have been some improvements since part two, especially in the handing of commas and periods, capitalization correction, etc. 

So, let's start by counting the number of times each term occurs in a document. This was already done for computing TF-IDF but the information wasn't saved but its easy to get again.

    #!python
    import json
    from collections import defaultdict
    import operator
    
    terms = defaultdict(int)
    
    with open('articles.txt') as f:
        linenum = 0
        for line in f.readlines():
            linenum += 1
            try:
                d = json.loads(line.strip())
            except ValueError as ve:
                print "Failed to parse line %d: %s: %s" % (linenum, line, ve)
            for t in d['terms']:
                terms[t] += 1
    
    # Drop all terms with an incidence less than 4
    for t in list(terms.keys()):
        if terms[t] < 4:
            del terms[t]
    
    ranked = sorted(terms.items(), key=operator.itemgetter(1), reverse=True)

The top terms I got out of this are 'is' and 'are', so its clear that the top_words list could do with some more stop words, but that doesn't really matter. I put together a new list of about 700 stop words I will use in future, and filter those out below:

    #!python
    with open('stopwords.txt') as f:
        stopwords = [l.strip() for l in f.readlines()]

    for t in list(terms.keys()):
        if t in stopwords:
            del terms[t]    
        
    ranked = sorted(terms.items(), key=operator.itemgetter(1), reverse=True)

That still leaves me with about 50,000 terms, with about 25% of that being terms that occur 4 or 5 times only. There are some interesting terms in there but clearly it would be costly to deal with that many. Sticking with capitalized terms cuts things down to about 15000. This would still be a lot of work to categorize so I think its time to take a different tack and try using gensim. My hope is that gensim can do better clustering than I got with affinity propagation and I can use the results to in turn extract the initial category term sets. Let's see what it can do. The code below will use Latent Dirichlet Allocation to cluster the articles into 200 clusters. First we need to turn our articles into term lists expanded out by term count (so if 'recipe' appears four times we need to make four copies; it is unfortunate that gensim will turn that back into a bag but doesn't seem to be able to take an existing bag as input).

    #!python
    stoplist = set(stopwords)

    documents = []
    with open('articles.txt') as f:
        linenum = 0
        for line in f.readlines():
            linenum += 1
            try:
                d = json.loads(line.strip())
            except ValueError as ve:
                print "Failed to parse line %d: %s: %s" % (linenum, line, ve)
            terms = []
            for k, v in d['terms'].items():
                if v > 1 and k not in stoplist:
                    terms.extend([k] * v)
            documents.append(terms)
            
Next we get gensim to create a sparse matrix model of the corpus and do LDA:

    #!python
    from gensim import corpora, models, similarities
 
    dictionary = corpora.Dictionary(documents)
    dictionary.save('articles.dict') 
	
    corpus = [dictionary.doc2bow(text) for text in documents]
    corpora.MmCorpus.serialize('article.mm', corpus)
	
    # extract 200 LDA topics, using 1 pass and updating once every 
    # 1 chunk (1,000 documents)
    lda = models.ldamodel.LdaModel(corpus=corpus, id2word=dictionary, 
        num_topics=200, update_every=1, chunksize=1000, passes=1)

It takes a few minutes to run but its worth it! The result is a set of vectors that give the the most important words and their weights for the cluster. A lot of these don't make sense but quite a number do - certainly enough to give the centroid articles I need. For example:

    u'0.060*cup + 0.055*kitchen + 0.039*sugar + 0.038*baking + 0.034*size + 0.034*milk + 0.031*recipe
     + 0.030*cheese + 0.026*dough + 0.025*bread' 
  
gives a set of important words for cooking/recipes category, while:

    u'0.273*God + 0.050*playing + 0.038*exercise + 0.030*Bible + 0.025*religion + 0.023*argument +
     0.020*prayer + 0.016*religious + 0.016*claims + 0.014*mercy',

gives some for religion. I may need more than 200 clusters but this is a good start. More to come!

