---
title: Building a Zite Replacement (Part 6)
date: 2015-09-24T20:31:00
author: Graham Wheeler
category: Programming
comments: enabled
---


Following on from last episode, I took some of the clusters that had clear cohesion and made some initial category exemplars. Here are the first few:

    #!python
    {"title": "Art", "terms": ["canvas", "painting", "pastels", "sculpture", "gallery", "photography",
            "landscape", "portrait", "still-life", "exhibition", "sketch"]}
    {"title": "Literature", "terms": ["novel", "writer", "plot", "character", "author"]}
    {"title": "Religion", "terms": ["Jesus", "Christianity", "Allah", "Islam", "Judaism", "Sufi",
            "Hindu", "karma", "sprituality", "faith", "belief", "priest", "pastor", "prayer"]}
    {"title": "Cooking", "terms": ["ingredients", "bake", "roast", "fry", "stir", "cook", "cooking",
            "recipe", "flour", "sugar", "butter", "cups", "cup", "teaspoon", "tablespoons", "vanilla"]}

Note that these are deliberately in the same format as the articles in articles.txt, although without as many fields.
<!-- TEASER_END -->

I then modified the code that reads in the articles file and calculates the TF-IDF similarity matrix to first read this file (categories.txt) so that these become the first 4 articles, then I recomputed the matrix.

I then sorted each item by similarity with each of these category items, and printed out the top 20, with:

    #!python
    import operator
    
    for category in xrange(0, 4):
        print "===\n%s" % items[category]['title'].upper()
        
        metrics = [[distance_matrix[category, i], i] for i in xrange(0, len(items))]
        ranked = sorted(metrics, key=operator.itemgetter(0), reverse=True)
     
        for r in ranked[0:20]:
            print items[r[1]]['title']

The results are show below although I shortened it to 10 for brevity. As you can see we have good category classification. Obviously though there is a long way to go in adding more category records. One benefit of this approach is that unlike clustering, an item can occur in the top n list for multiple categories, which is desirable.

```
ART
“Tapestry Hill,” contemporary landscape painting
Sailing off King Billie, oil painting on box canvas
Alcarte 2014 - Collective Exhibition
Contemporary cat painting “Feline Focus”
butterfly painting tutorial
"Two deckchairs" oil painting
Comment on Liverpool residents take a shot at creating the city’s biggest online photography exhibition by Debra Kurs
Exhibition Site
First portrait painting in oil paint (2nd stage) tutor Colin Pethick.
First portrait painting in oils, workshop with Colin Pethick (1st stage)
===
LITERATURE
Agent Orange
Gauntlet
In Which I Contemplate the Details
Author Kurt Andersen Pens Novel with PWD Perspective
Donald Trump will publish a new book in October. Will it be huuuge?
Comment on Book Review: Echo by Pam Muñoz Ryan by Anonymous
Comment on Writing Your Novel: Become Your Best First Editor by Writing Fiction Made Easier: Get Out Of Backstory Hell
PRATIBIMB - BOOK COVER PAGE DESIGN for India's young and dynamic writer Dr. Bhavesh Joshi (Bharavi).
What Is Best in Life?
Comment on LADIES AND GENTLEMEN… by eva
===
RELIGION
Comment on Children, a gift of Allah! by www.alquranonlinelearning.com
Marble Church Sermon
I hated Islam
Susan Carland - journey to Islam
Lauren Booth - My journey to Islam
Bart Ehrman - Jesus and Contradictions In The Bible
Convert to Islam 2013
Dr. Geoff Tunnicliffe - faith leaders on the forefront
Ten Reasons why Jesus (upon him peace) is not God
Islamic beliefs – Islam – ????? ????????
===
COOKING
Blueberry Pie Recipe
4th of July BBQ Hot Dog Cupcakes
Upside-Down Cake Recipe
Chocolate Ovaltine snacking cake - easy to make and delicious
Comment on Instant Raw Applesauce by 5 Things You Can Make In Your Blender That Aren't SmoothiesMy Weight Loss Blog | My Weight Loss Blog
Comment on Lemon Chiffon Cake Recipe by Katie
Cooking up a storm with our Crisis Program Cooking Group
Thai Basil Chicken
Skratch Recipe of the Week; Sweet Cream Grits
Comment on Foolproof Yorkshire Pudding Recipe by pearl
```

In summary, we can now take articles, extract a set of key terms, and assign them to one or more categories. There is obviously work to be done, tuning the categories over time and adding many more. One way to determine how to adjust the key terms for existing categories is to look at the top terms across all articles assigned to that category, and add them to the category terms if they aren't already present.

I'll probably be busy with this for a few days but once I have a good working system the next topic will be ranking. Ranking will work best in conjunction with crowdsourcing so I may need to build the system out as far as a simple web front end that can be used as a categorical RSS search engine. Watch this space for future developments!

