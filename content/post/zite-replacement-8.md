---
title: Building a Zite Replacement (Part 8)
date: 2015-10-31T20:21:00
author: Graham Wheeler
category: Programming
comments: enabled
---

Happy Halloween, all!

I'm sitting here handing out candy and glow necklaces to all comers so its a
good time to write a new post.

It's been a while since much happened as I've been really busy with the beta 
release of Google Cloud Datalab, which is my day job. But now that is out and
it's the weekend and lousy weather here in the Pacific Northwest it's been a 
good day t get back to things.

Today I did something I've been meaning to do for a while, which is to change
the code to populate a MongoDB database rather than writing files to the file 
system. Interestingly it seems to be quite a bit slower than the file system 
but hopefully it will scale better and make up for things when I have ad-hoc
queries to do.
<!-- TEASER_END -->

I hadn't used MongoDB before so it was a learning opportunity. Mongo is a 
no-SQL database that stores *collections* of *documents* in its databases,
rather than tables of records, so it is well suited
to storing the JSON RSS feed objects. It's very easy to use too. I modified
my exitisting code to take two callbacks, one to create an ID from an article, 
and the other to save the article give the ID. For the old code, the ID just
corresponds to the pathname of the file, and saving just saves the JSON as a
string to that file. The ID creator has a secondary role of checking if we have
already fetched that object before, in which case we don't need to save it.

Each document has a special unique key '_id', and can have secondary keys. The
document itself is an ordered set of keys with associated values (which can
themselves be documents), so this maps reasonably well to Javascript objects.
Keys are any UTF-8 strings but should avoid '$' and '.' which have special 
usage, and NUL which is used as a key terminator. Keys must be unique, and are case sensitive.

Collections (groups of documents) can store different types of documents; they do
not have a fixed schema. That said, it is generally more sensible and efficient
to keep similar documents in the same collection, and make use of multiple 
collections, rather than putting everything in one collection. Collection names
are non-empty UTF-8 strings that don't include NUL or '$' and don't start with 
'system.' (the latter two constraints are for implementation-specific reasons).

Database names should be non-empty alphanumeric ASCII strings of 64 bytes or less 
(not actually quite that restrictive but that's a good guideline). 'admin' is a
special root database, and 'config' is a special database that stores sharding 
information. 'local' is a database that can be used to store collections that should
not be replicated.

I now have an articles collection, and my
callbacks to use Mongo just look like this:

    #!python
    import pymongo

    def make_id(metadata):
        id = metadata['guid']
        if articles.find_one({'guid': id}):
            # We already have this article so no need to save it...
            return None
        return id

    def handler(id, metadata):
        articles.insert_one(metadata)

Very simple, no? But I'm getting a bit ahead of myself; it's worth mentioning 
how I installed Mongo. You can download it from mongodb.org. I went for 
version 2.6 rather than 3 as there is a nice free GUI tool for inspecting 
and querying the database called RoboMongo and it doesn't work yet with Mongo 3.

If you download the Mac version of Mongo you get compiled binaries, not an
installer. These need to be put in your path somewhere. I use Homebrew for 
some software on the Mac so I already have a /usr/local/bin directory in
my path, and just put the Mongo files there. I know, this is polluting the
Homebrew install somewhat, but it seemed the most practical anyway. You then
need to create a directory for the databases, which by default on the Mac should
be /data/db. Make sure you have write permission, or at least the user account
that is going to run the mongo server does. You can then start Mongo by running
'mongod' at the command line.

Mongo creates databases and collections when they are accessed which makes 
things very simple. The initial code in my fetcher looks like this:

    #!python
    import datetime
    import sys
    import pymongo

    if __name__ == '__main__':
        con = pymongo.MongoClient()
        # Creates DB if needed
        db = con.feed_database
        # Creates collection if needed
        articles = db.articles
        feedlist = sys.argv[2] if len(sys.argv) > 2 else 'feeds.txt'
        start = datetime.datetime.now() - datetime.timedelta(days=30)
        # Do the fetch.

I mentioned before how I changed the fetcher to use parallel fetches. That 
uses the Python thread library, so the code continues:

    #!python
        dictionary = set(feedlib.load_list('dictionary.txt'))
        stop_words = set(feedlib.load_list('stopwords.txt'))

        # Spawn 20 fetchers
        for i in range(20):
            t = Fetcher(queue, start, articles, dictionary, stop_words)
            t.setDaemon(True)
            t.start()

        # Queue up the feeds and wait until done.
        feed_list = sys.argv[2] if len(sys.argv) > 2 else 'feeds.txt'
        for feed in feedlib.load_list(feed_list):
            queue.put(feed)
        queue.join()

Each thread is handled by an instance of the Fetcher class:

    #!python
    class Fetcher(threading.Thread):

        def __init__(self, queue, start, articles, dictionary, stop_words):
            super(Fetcher, self).__init__()
            self.queue = queue
            self._start = start
            self._articles = articles
            self._dictionary = dictionary
            self._stop_words = stop_words

        def run(self):
            while True:
                feed = self.queue.get()

                try:
                    feedlib.process_feed(feed, self._dictionary,
                                         self._stop_words,
                                         start_date=self._start,
                                         idmaker=idmaker, handler=handler)
                except Exception as e:
                    msg = "Failed to process %s: %s" % (feed, str(e))
                    print msg
                    logging.getlogger().error(msg)
    
                self.queue.task_done()


