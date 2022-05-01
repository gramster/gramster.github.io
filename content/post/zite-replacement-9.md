---
title: Building a Zite Replacement (Part 9)
date: 2015-11-01T22:07:00
author: Graham Wheeler
category: Programming
comments: enabled
---

Well, I hope you've all brushed your teeth after all that Halloween candy.

Today I'm going to show how I build a simple web server to view my feed
articles using node.js and Express, along with MongoDB. I have a simple 
category classifier which finds the best Jacard similarity (described earlier)
to a set of category exemplars (i.e. 'pseudo-articles' for a category
containing just key words that are typical for that category). It needs a
lot of tuning and the earlier tkInter program was meant for that but tkInter 
proved to have problems. So time to use some more modern techologies!
<!-- TEASER_END -->

I gave an overview of node in an earlier article; if you have no familiarity
with node you should go read that first. I'm not going to go into 
much detail here about installation, etc; if you want to try this you can 
easily install node for your platform. We're going to generate a scaffold 
Express app with a generator, so we need to install that along with its
dependencies:

    #!bash
    npm install -g express-generator

and then generate the skeleton in a 'server' subdirectory:

    #!bash
    express server
    cd server

This skeleton will include a package.json file; we need to edit that and
add these to the end of the dependencies section (make sure to add a comma
on the previous last line in the dependencies):

    #!javascript
    "mongodb": "~2.0.33",
    "monk": "~1.0.1"

Then install the dependencies:

    #!bash
    cd server
    npm install

Although we'll be adding some more and need to rerun this again later.

We need to tell node to use our database. To do that, we edit app.js
and before the line that says:

    #!javascript
    var routes = require('./routes/index');

we add:

    #!javascript
    var mongo = require('mongodb');
    var monk = require('monk');
    var db = monk('localhost:27017/feed_database');

(I called my MongoDB feed_database; you would need to use a different name
for a different database).

To make the database accessible to our page handler, before the line that says:

    #!javascript
    app.use('/', routes);

we add:

    #!javascript
    app.use(function(req,res,next){
        req.db = db;
        next();
    });

This will add a property 'db' to each request that points to out database so
each request handler has easy access to the database.

Our server will use the local URL /categories for a page with the 
list of categories that have articles. Each of these will in turn link
to an /articles page which will show the titles of articles for that
category, and link back to the source. To set up the routes we need to edit
routes/index.js, and add our additions (before the modules.exports
line at the end):

    #!javascript
    /* GET categories page. */
    router.get('/categories', function(req, res) {
        var db = req.db;
        var collection = db.get('articles');
        collection.distinct('classification', function(e, docs) {
            res.render('categories', {
                "categories": docs
            });
        });
    });

    /* GET articles page. */
    router.get('/articles', function(req, res) {
        var db = req.db;
        var collection = db.get('articles');
        collection.find({'classification': req.query.category},
            function(e, docs) {
                res.render('articles', {
                    "category": req.query.category,
                    "articles": docs
                });
            }
        );
    });

The /categories page router finds all distinct values for the 'classification'
field (which I use to put my categorization of an article, as they already
have a 'Category' field which is part of RSS). It then renders a page using
a 'categories' template and passes the template an object with a 'categories'
property which has the resulting document returned by the database. The
template engine is Jade which Express uses by default.

We'll look at the /article page route in a moment; first look at the 
template for the categories page which we create in file views/categories.jade:

    #!text
    extends layout

    block content
      h1.
        Categories
      ul
        each category in categories
          li
            a(href="articles?category=#{category}")= category

This is pretty simple. Jade uses indentation for hierarchy so that is important
to get correct. We create a heading and a list, with each list entry
being a category name in the form of a link to the /articles page with a 
query parameter for the category. Now the /articles router should be easy
to understand. We find all documents in the database that have the same
classification as was specified in the category query parameter in the request
URL, and render the page using the article template, passing that template
the article list and category name. That template looks like:

    #!text
    extends layout

    block content
      h1.
        Articles for #{category}
      ul
        each article in articles
          li
            a(href="#{article.link}")= article.title

Very similar to the category one except we put article titles in the list and
our links refer to the original article links, so clicking on a title will
take us to the web page for that article. Pretty simple!

Now we can run this:

    #!bash
    npm start

and navigate to http://localhost:3000/categories to see what we might want to
read!


