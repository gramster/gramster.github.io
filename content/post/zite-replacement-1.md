---
title: Building a Zite Replacement (Part 1)
date: 2015-09-19T14:12:00
author: Graham Wheeler
category: Programming
comments: enabled
---

The two most used apps on my phone are [Zite](http://zite.com/) and [Pocket](https://getpocket.com/). Unfortunately last year Zite was bought by Flipboard and has slowly been getting worse. Recently the top sticky article on Zite has been a post on migrating your preferences to Flipboard, but suggests Zite is not much longer for this world.

This would be okay if Flipboard was a suitable replacement, but it isn't. It's very flashy (which I don't like), and just doesn't seem to get things right when it comes to serendipitous discovery of interesting content. My feeling is that it is probably a great app for people who are interested in news and pop culture, but my interests run more specialized; I want to read about certain programming languages and fields of math, computer science and statistics.
<!-- TEASER_END -->

A few days ago Zite had a half day outage and I decided that it was time to hedge my bets. If no-one else has made the app that I want, I'll just have to do it myself.

So what is involved? Amongst other things:

 - a corpus of documents of potential interest
 - a way of determining the topics discussed in each document
 - a way of classifying the documents into a broader set of categories, based on the topics
 - a way of ranking each document within the category
 - a database or some other store for the results, and an API to query these
 - an app to consume the resulting content in a way that is easy to use, efficient, and supports various options like blocking sites that are not interesting, upvoting/downvoting the suggested results to improve future results, and saving/sharing the results. Such an app would require some form of identity for personalization, assume I'm not the only one using it.

Apart from the app part, the rest of these are all back-end server tasks, and while the amount of data to be processed may be large the task is not too hard. As for the app, I realized an easy solution at first is to not build an app at all. There are other ways to consume the results; for example a daily digest e-mail, or saving the results straight to an app like Pocket or Evernote from where they can be read/deleted/etc. This loses the ability to upvote/downvote/etc but that can come later.

As for the corpus of documents that serve as input, there are a number of ways to source these:

- RSS feeds are an obvious first choice
- Digest-style e-mails that contain useful sets of links - e.g. O'Reilly has weekly newsletters in areas like Programming, Big Data, etc that can be great input (especially as it is already curated)
- Posting on social community groups like G+ communities
- Twitter, Facebook and LinkedIn postings by thought leaders 

These are just a few ideas; the first source will definitely be RSS feeds though as they have many useful properties in their metadata.

The main other challenge is the classification task. This is typically going to involve supervised machine learning which means you need a large collection of previously classified articles to learn from.  Thankfully RSS includes article categories so hopefully that will be enough to go on.

Anyway, enough talk. In my next posting I'll look at how to do step 2, namely topic extraction, from RSS feeds.


