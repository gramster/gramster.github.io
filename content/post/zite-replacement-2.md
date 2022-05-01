---
title: Building a Zite Replacement (Part 2)
date: 2015-09-19T16:18:00
author: Graham Wheeler
category: Programming
comments: enabled
---


In the [previous post](http://www.grahamwheeler.com/posts/zite-replacement-1.html) I gave an overview of what needs to be built for our [Zite](http://zite.com/) replacement. In this post we will look at how to load an RSS feed and generate key terms for each article. In order to fetch the feed we will make use of the [feedparser](https://pypi.python.org/pypi/feedparser) package, so make sure to install that first with pip, conda, or whatever you use.

Another thing we're going to want is to strip HTML tags from the articles. I did a Google for "HTML element stripper Python" and found [this StackOverflow post](http://stackoverflow.com/questions/753052/strip-html-from-strings-in-python) with the code below that works great:
<!-- TEASER_END -->

```python
#!python
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
```

With that, let's begin. One of the things we will want to do is normalize capitalization of words. In particular, the first word in a sentence is capitalized and we want to in most cases undo that so we don't see two forms of the same word. One solution is to lower-case everything but that is throwing the baby out with the bathwater. A better solution is to look up each word in a dictionary. If we fail to find a match we can try the lower-case form.

There are probably libraries already to do this (NLTK?) but I did some early prototyping of the code in this post using the top 5000 words from [this list](http://www.wordfrequency.info/free.asp). So for now I'll just use that as a dictionary to normalize words. There are much more comprehensive lists out there without frequency information and I expect I'll replace this but due to my early experiments I had the word list loaded already.

If you're interested in using that list, you can copy/paste it into a spreadsheet and save it as a CSV once you have agreed to the terms. I used the code below to load that CSV file. I also put the top 198 words in a separate list that I was going to use to remove [stop words](https://en.wikipedia.org/wiki/Stop_words), but I ended up not needing that.


```python
#!python
import csv

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
    if count <= 198:
        top_words.append(word)
    words5000[word] = v
    total += v
```

Next we will use a function that gets a dictionary with the words and counts from an article, and returns that plus the total number of words in the dictionary. It will do all the necessary work to strip tags, punctuation, and so on before computing the counts.

```python
#!python
import re
import string 

def get_article_terms(article):
    """
    Get the terms and counts from an article. Strip HTML tags and
    non-essential punctuation, whitespace, and single
    character 'words' like s that may come from punctuation removal.
    Try normalize initial letter case using the 5000 word dictionary.
    Return a set of words and counts and a total count.
    """
    terms = {}
    total = 0
    # Remove the HTML element tags
    article = strip_tags(article)
    # replace non-ASCII chars with space
    article = re.sub(r'[^A-Za-z\-]+',' ', article)
    # We could use a Counter here but the would need to post-process the keys 
    # to remove the bogus ones and correct capitalization. Consider for later.
    for term in article.split(' '):
        if len(term) < 2 and (term != 'a' or term == 'A' or term == 'I'):
            continue
        total += 1
        # Update the count. If the word is a new one then see if the lower
        # case form is in our dictionary and use that in preference.
        if term in terms:
            terms[term] += 1
        else:
            lterm = term.lower()
            if lterm in words5000:
                term = lterm
            terms[term] = 1

    return terms, total
```

The method we will use to get topics is something called [Term Frequency-Inverse Document Frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf) (TF-IDF). It essentially works by taking the frequency of a term in a document, and multiplying it by the log of the inverse of the number of documents the term occurs in. The idea is that the key terms will be words that occur frequently in *this* document relative to how frequently they occur in *all* the documents. Obviously words like 'the', 'and', etc have a high frequency in most documents, so they aren't interesting. But if a word that is uncommon in all the documents, like, say, 'pneumonia', occur relatively higher in a specific document, then that word is likely important.

A key part of this is that we need to count how many documents a word occurs in, not just how often it occurs in each document. So our next function is going to look at all the articles in a feed. Ideally we would compute the IDFs from a bigger corpus of documents, so that can be refined later (in fact, I used the top 5000 words as an alternative and they worked quite well too, but if every article in a feed include some boiler plate text, using the top 5000 words may not filter that out, but computing IDF just from the articles will).

```python
#!python
import collections
import feedparser

def get_article_data(feed_url):
    """
    Calculate the term counts for each article in a feed as well as
    the document counts for each term. Return a list of article metadata
    including the title, a snippet, the distinct terms and their counts, etc,
    as well as the counts of how many documents each term appeared in.
    """
        
    d = feedparser.parse(feed_url)
    
    doc_terms = collections.Counter()
    articles = []
    
    entries = d['entries']
    for entry in entries:
        title = entry.get('title', None)
            
        # For some sites seem we get summary and some content
        summary = entry.get('summary', None)
        content = entry.get('content', None)
        article = summary if content is None else content
        
        terms, count = get_article_terms(article)
        doc_terms.update(terms.keys())
        articles.append({'title': title, 'leader': article[:100],
                        'terms': terms, 'count': count, 
                        'link': entry.get('link', None),
                        'date': entry.get('published_parsed', None)})
    return articles, doc_terms
```

Now we can use this function to compute the TF-IDFs for all the articles in a feed:

```python
#!python
import math
    
def get_feed_with_tf_idf(feed_url):
    """ Calculate TF-IDFs for each article in a feed and add to metadata """
    articles, doc_terms = get_article_data(feed_url)
    for article in articles:
        terms = article['terms']
        tf_idf = {}
        article_count = float(article['count'])
        for term, count in terms.items():
            tf_idf[term] = (count / article_count) * math.log(len(articles) / float(doc_terms[term]))
        article['tf_idf'] = tf_idf
    return articles
```
    
And we're basically done! Let's see how well it worked. We can try it out on the HuffPost and print out the top ten terms for each article:


```python
#!python
import operator

articles = get_feed_with_tf_idf('http://www.huffingtonpost.com/feeds/index.xml')
for article in articles:
    rank = sorted(article['tf_idf'].items(), key=operator.itemgetter(1), reverse=True)
    print '%s\n%s\n%s\n' % (article['title'], article['leader'], 
                            '\n'.join(x[0] for x in rank[:10]))
```

Running this right  now gives the results below. Not bad for a first attempt! Note that the titles that are printed out were not included in the term counts and so are a good test (although in practice it would make sense to include these so they can help rank the terms).


	iPhone Shopping? Beware: Madness Ahead!
	If you're thinking of upgrading your aging iPhone - I've just gone through all the pain and sufferin
	iPhone
	ATT
	Verizon
	phone
	customers
	line
	phones
	sell
	you
	month
	
	Ted Cruz Declines To Say Whether He Thinks Obama Is A Christian
	<div class="embed-asset embed"><br />
	        <div class="embed-code"><span class="js-fivemin-script
	Cruz
	Christian
	president
	policies
	speculate
	Muslim
	contributed
	comments
	Obama
	faith
	
	How to Help Shatter the Class Ceiling - Elect Bernie Sanders
	Let's make history. The 2016 election offers a rare moment to crack a barrier that can truly transfo
	percent
	Sanders
	poverty
	income
	Sen
	far
	African-Americans
	wealth
	trillion
	households
	
	2-Year-Old Baby, 2 Others Gunned Down Inside Utah Home
	<br />
	<p class="ap-story-p">SALT LAKE CITY (AP) -- Police in Utah arrested a 32-year-old man on Sat
	Chipping
	Tran
	inside
	boy
	-year-old
	home
	victims
	arrested
	Poike
	bodies
	
	Pope Francis Praises U.S.-Cuba Detente As Model For World
	<br />
	<p>HAVANA (AP) &mdash; Pope Francis hailed detente between the United States and Cuba as a mo
	Cuba
	Francis
	visit
	Cuban
	pope
	Raul
	United
	reconciliation
	airport
	travel
	
	Reminding Yourself You're F&^*% Hot (Step 1)
	Ladies, there are so many facets in our struggle of masculine dominated life that project us to eith
	Kyle
	hot
	hotness
	itself
	swear
	moment
	was
	re
	know
	exact
	
	A Pope That Congress Should Listen To
	When the Pope takes center stage in the heart of the nation's capital next Thursday, Americans will 
	Pope
	values
	village
	community
	energy
	Iran
	person
	culture
	peace
	world
	
	Donald Trump & Vaccines: Is He Ready To Be Responsible For A Children's Epidemic?
	<strong>Donald Trump may be a big blowhard, espousing his belief that there's a link between vaccine
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
	
	What You Should Do If You Own A Volkswagen That Was Just Recalled
	<div class="embed-asset embed"><br />
	        <div class="embed-code"><span class="js-fivemin-script
	Volkswagen
	vehicles
	loaner
	recalled
	car
	cars
	risking
	diesel-power
	vehicle
	safety
	
	5 Reasons People May Not Be Following Your Leadership
	There are times throughout a leader's tenure that he/she must look behind them and see if anyone is 
	team
	lead
	leader
	regularly
	disorganized
	leadership
	clarity
	praise
	follow
	you
	
	How To Deal With These 3 Difficult Managers At Work
	One of the biggest challenges for any employee is learning how to work well with a manager. A good w
	manager
	Gary
	Pleasing
	Patricia
	personality
	difficult
	Mitchell
	Micromanaging
	Goal-Focused
	she
	
	Experts: Cybersecurity Attacks Slow Ahead Of Obama's Meeting With Chinese President
	<br />
	<p>WASHINGTON, Sept 19 (Reuters) - Major intrusions by Chinese hackers of U.S. companies' com
	Chinese
	cybersecurity
	Mandia
	China
	said
	breaches
	companies
	McClure
	Inc
	Xi
	
	6 Tips for the Unmotivated Student: How to Stay on Track After the First Week of School
	<em>Co-authored by <a href="https://twitter.com/just1trunk" target="_hplink">Ashley Carter</a>, staf
	study
	buddy
	semester
	your
	home
	media
	studying
	excited
	coffee
	finding
	
	3 Proven Ways To Help You Achieve Your Goals
	It's sad to think how many people go their whole lives dreaming of goals that they will never hit. W
	goals
	hit
	everyday
	everything
	your
	ll
	business
	want
	habit
	consistent
	
	Huckabee: Obama Nominated Openly Gay Army Head To 'Appease Homosexuals'
	<div class="embed-asset embed"><br />
	        <div class="embed-code"><span class="js-fivemin-script
	military
	Fanning
	Huckabee
	Carter
	gay
	nomination
	openly
	undersecretary
	appointment
	experiments


