---
title: Building a Zite Replacement (Part 7)
date: 2015-10-04T21:31:00
author: Graham Wheeler
category: Programming
comments: enabled
---

It's been a while since the last post but I haven't been idle. Here are some of the things I've been up to:

 - tweaking the code to parse content better 
 - moving from IPython notebook to a library that I can use to do batch operations as well as interactive exploration modifying the code do do parallel fetches - or more precisely, to operate asynchronously; because of the Python GIL I still have just one thread for now. But I can kick off up to 40 HTTP requests at a time which speeds things up a lot, as I have about 4000 sites I'm working with now;
 - exploring the [TextBlob library](http://textblob.readthedocs.org/en/dev/), a library that sits above the [Python NLTK](http://www.nltk.org/) and can parse sentences and words (more on that below)
 - building a GUI application with [Tkinter](https://wiki.python.org/moin/TkInter) that lets me quickly view feeds, terms, categories and articles, delete feeds, tweak category examplars and see the results, and so on. This has been invaluable in building up and fine tuning my category examplars, although it is still a work in progress. It's been somewhat painful as I haven't used Tk in about two decades but I've mostly got it to do what I want.
<!-- TEASER_END -->

You can see a screenshot of the GUI below to get an idea of what it looks like:

[![feedme app screenshot](/img/feedme_screenshot.png "feedme app screenshot")](/img/feedme_screenshot.png)

This is meant just for my use so its functional rather than polished.

The TextBlob library is worth investigating if you are considering doing anything like this. In the end I abandoned it because the code I have written for parsing sentences and words is almost as good and about an order of magnitude faster. But I will show the code I experimented with so you can see how easy it is to use. Below is the code for getting the term counts for an article downloaded with feedparser. Note that I still handle correcting the capitalization of initial words in sentences, and I use my own logic for extracting noun phrases; TextBlob has code for that but it is seemingly not very good. The key thing is to note that I don't have to do much at all to get at sentences and then at words within sentences:

    #!python
    from textblob import TextBlob
	
    def get_article_terms(title, article, dictionary, stop_words):
        blob = TextBlob(title +'. ' + strip_tags(article))
        terms = []
        for sentence in blob.sentences:
            first = True
            noun_phrase = []
            for word in sentence.words:
                if first:
                    first = False
                    if word not in dictionary and \
                        word.lower() in dictionary:
                        word = word.lower()
                if word[0].isupper():
                    noun_phrase.append(word)
                else:
                    if len(noun_phrase):
                        terms.append(' '.join(noun_phrase))
                        noun_phrase = []
                    if word not in stop_words:
                        terms.append(word)
            if len(noun_phrase):
                terms.append(' '.join(noun_phrase))
        term_counts = collections.Counter()
        term_counts.update(terms)
        return term_counts, len(terms)


Anyway, as I say, this works but it is slow and I have a much faster version:

    #!python
    def get_article_terms(title, article, dictionary, stop_words):
        """ Get the terms and counts from an article. Strip HTML tags and
        non-essential punctuation, whitespace, and single
        character 'words' like s that may come from punctuation removal.
        Try normalize initial letter case using the supplied dictionary.
        Remove stop words, and return a set of words and counts and a total count.
        """
        article = title + '. ' + strip_tags(article)
        # replace non-ASCII chars with space. We keep '-', '.', ',', '\''.
        article = re.sub(r'[^A-Za-z0-9\.,\-\']+',' ', article)
        # Split on '.' and check first words to see if they should be lower-cased.
        sentences = article.split('.')
        article = ''
        for sentence in sentences:
            words = [w for w in sentence.split(' ') if len(w)]
            if len(words):
                if words[0] not in dictionary and words[0].lower() in dictionary:
                    words[0] = words[0].lower()
            words.append(',')
            article += ' '.join(words)
    
        # Look for consecutive sequences of capitalized words with no intervening
        # punctuation other than '-' and turn them into single terms with '_'
        # replacing space so we can temporariliy treat noun phrases as single words.
        sentences = article.split(',')
        article = ''
        for sentence in sentences:
            words = [w for w in sentence.split(' ') if len(w)]
            for i in range(0, len(words) - 1):
                if words[i][0].isupper() and words[i + 1][0].isupper() and words[i] != 'I' \
                    and words[i+1] != 'I':
                    words[i + 1] = words[i] + '_' + words[i + 1]
                    words[i] = ''
            words.append(' ')
            article += ' '.join(words)
    
        # replace non-ASCII chars with space. We keep '-' and underscore.
        article = re.sub(r'[^A-Za-z0-9\-_\']+',' ', article)
        # Get the non-empty words that aren't stop words, and while
        # we are at it, fix up underscores in noun phrases.
        terms = [term.replace('_', ' ') for term in article.split(' ') if len(term) \
            and term not in stop_words]
    
        term_counts = collections.Counter()
        term_counts.update(terms)
        return term_counts, len(terms)


The next step for me is to start using my category examplars to categorize new articles on a daily basis so I have a manageable quantity I can sanity check. With a bit more tuning I want to build a simple web front end to this so I can open it up for others to try and provide feedback. Watch this space!


