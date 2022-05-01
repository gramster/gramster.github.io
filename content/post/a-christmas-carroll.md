---
title: A Christmas Carroll
slug: a-christmas-carroll
date: 2011-03-29T22:11:00
tags: 
category: Math
author: Graham Wheeler
comments: enabled
has_math: yes
---

On Christmas day, 1877, Lewis Carroll, author of the Alice books,
entertained two bored young girls by inventing a new game that he called
Word Links: given two words, change one word to the other by changing a
single letter at a time with the intermediate steps all being valid
words themselves. For example, to change "cold" to "warm", one can use
the steps "cord", "card", "ward". Carroll later popularised this form of
puzzle in a series of articles in Vanity Fair magazine, changing the
name to Doublets - from the "double, double, toil and trouble" witches'
incantation in Shakespeare's Macbeth.
<!-- TEASER_END -->

These puzzles are still popular today (usually called Word Ladders). The
noted Stanford computer sciencist Don Knuth dedicated several pages of
his work on graph algorithms (The Stanford Graphbase) to the topic.
Knuth investigated five-letter words and found that of a set of 5,757
common English words, there were 14,135 links between words (where a
link is a single ladder step). Only 671 words had no links - Knuth
called these words 'aloof' - 'aloof' itself being aloof, along with
words such as 'earth', 'ocean', 'sugar' and 'laugh'. 103 pairs such as
'opium' and 'odium' exist. The two biggest connected sets have 25 words
each. By relaxing the rules - for example by allowing the letters to be
rearranged at each step - the words become considerably more connected.

Ted Johnson [conducted an analysis of four letter
words](//users.rcn.com/ted.johnson/fourletter.htm), with the additional
rule of allowing the word to be reversed at any step. Starting with an
online dictionary of 4776 words, he found that there was one huge linked
component of 4436 words. This is not surprising; in 1960 Paul Erdős and
Alfred Rényi proved that if the average number of links is sufficiently
high then[the set of words will form one large connected component with
a few outliers](http://en.wikipedia.org/wiki/Erdős–Rényi_model).
Word ladders are interesting because of their similarity to genetic
mutation in DNA. Carroll himself came up with the evolutionary chain
'ape', 'are', 'ere', 'err', 'ear', 'mar', 'man', although he was a
sceptic of Darwin's theories.

Consider the subsequence from 'err' to 'man' - can you prove that to
change one word with a single vowel to another word with a single vowel
but in a different position, that it is necessary to go through an
intermediate step of a word with two vowels? For the purpose of this
problem, consider 'y' to be a vowel.
