---
title: Building a Zite Replacement (Part 11)
date: 2016-04-23T09:15:00
author: Graham Wheeler
category: Programming
comments: enabled
---

It's been a while since I worked on this but it is still on my mind a lot. I've been mulling over ways to improve categorization without the semi-supervised tweaking I've had to do.

Just to recap, currently this is what I am doing:

* I have a bunch of 'category exemplars', which are sets of key terms associated with a category. These are the things which currently require some manual work;
* for each article, I extract the plain text, normalize capitalization, remove [stop words](https://en.wikipedia.org/wiki/Stop_words), then use [tf-idf](https://en.wikipedia.org/wiki/Tf-idf) to extract the set of most significant terms (I'm not yet doing [stemming](https://en.wikipedia.org/wiki/Stemming) although I'll probably start);
* I then use a [distance metric](https://en.wikipedia.org/wiki/Metric_(mathematics)) from the exemplars to assign category scores to the articles. Provided the score exceeds a threshold the article will be considered to be in the category.
<!-- TEASER_END -->

The manual work right now comes in when I notice [false positives and negatives](https://en.wikipedia.org/wiki/False_positives_and_false_negatives). My basic web app has the ability to show me all the common terms that led to a categorization and/or missed terms leading to a missed categorization. I can use these to tweak the category exemplars to improve classification. Its not ideal; I would far prefer to make this all be automated. The plan is to make use of Wikipedia to help with generating category exemplars. I don't think that this will solve the problem entirely but I am hoping to add one level of abstraction here to potentially reduce the amount of tweaking required.

My initial plan is:

* take each Wikipedia article, extract the plain text (and probably add stemming), remove stop words, generate term counts, and keep track of outgoing links to other articles
* reduce the set of articles to a manageable set. Keep only articles that have a reasonable length (after stop word removal), and at least a certain number of incoming links. The values to use here will be determined empirically once I have these values for the articles
* for each article, generate tf-idf scores for terms and keep the top terms (i.e. treat them much as my current category exemplars)

The good news is that this can all be automated. The bad news is I'm likely to have many thousands of 'categories'. But here is where a second level of abstraction comes in. For each article from the web I want to classify:

- generate the set of Wikipedia categories for the article (using cosine distance from the Wikipedia exemplars);
- use the Wikipedia categories as the new term sets for the articles when categorizing them

I.e. instead of categorizing an article based on the significant terms in the article, do so based on the significant Wikipedia categories for the article.

This may seem like a lot of work to come almost full circle but the hope is that these second level exemplars will be more stable and require less tweaking. As for generating the second-order exemplars, I can make use of all the articles I have categorized so far as a training set for supervized learning.

The next problem is dealing wth the Wikipedia dump. Uncompressed it is close to 60GB. The first task is to split it up into separate articles, which I pan to do with [WikiExtractor](https://github.com/attardi/wikiextractor). After that I may try use my little 4-node ODroid cluster to do the work, which will be a nice intro to my next couple of posts about that! 



