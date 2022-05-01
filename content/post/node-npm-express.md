---
title: Node, npm and Express
date: 2015-10-26T21:53:00
author: Graham Wheeler
category: Programming
comments: enabled
---

Things have been slow on the blogging front but there has been progress on the
Zite replacement. I'll write more about that soon but part of what I have been 
doing is looking into what server-side technology to use.

As far as a database goes, this seems like a no-brainer. I'm dealing with JSON
documents that I can either spend some effort on normalizing to put into a SQL 
database, or simply keep them as is and put them in a database that supports 
that form, and the obvious choice then is [MongoDB](https://www.mongodb.org/), 
which uses a binary form of JSON.
<!-- TEASER_END -->

As for what to use to handle network requests, there I am torn between
[Tornado](http://www.tornadoweb.org/en/stable/)
(which is Python) and [Node.js](https://nodejs.org/en/) (Javascript). I'm not 
a big fan of Javascript 
(despite having implemented Javascript compilers and virtual machines twice in 
my life!), primarily because it relies too much on sneaky tricks to do things
like encapsulation and OOP, but it certainly is the closest to a first-class
language for MongoDB, so I'm doing the investigation. I've had a small amount
of exposure to Node.js at work but mostly as a user, not developer, so what
follows are some of my initial notes on the topic of Node.js, the npm package
manager, and the Express web framework. I hope you find them useful if these
are new to you.

# Node.js

Node is a version of Chrome's v8 Javascript engine 
which includes a set of useful packages for server-side code (event-driven networking, 
file system etc) and a package manager, npm. Node was motivated by the need to handle 
large numbers of simultaneous sockets for HTTP long polling and web sockets; using 
separate threads or processes for each socket is too costly in resources (especially 
memory). Instead it uses the JS event loop and closure callbacks to scale efficiently.
 The underlying non-blocking socket code is written in C and wrapped in JS.

# CommonJS

CommonJS is a suite of standardized APIs for using Javascript on the server,
addresses namespacing among other things. For the latter it includes three key
components:

- require() method used to load a module
- exports object to expose code
- module object

Each module is a single JS file with isolated scope overridden by the exports object. 
E.g. consider a file hello.js:

    #!javascript
    var message = 'Hello';
    exports.sayHello = function() {
        console.log(message);
    }

which can then be used like:

    #!javascript
    var hello = require('./hello');
    hello.sayHello();

Alternatively we could have written:

    #!javascript
    module.exports = function() {
        console.log('Hello');
    }

and used:

    #!javascript
    var hello = require('./hello');
    hello();

# Node core modules

Core modules are compiled into the node binary, and include 'fs' for file
system access, and 'http' for network support. They still need to be loaded
with require(). See [http://nodejs.org/api/](http://nodejs.org/api) 
for more about the core modules.

# npm - The node package manager

npm can install packages and their dependencies locally (in ./node\_modules)
or globally with the -g option (in /usr/local/lib/node\_modules). You would
typically install common build tools like grunt globally, and dependencies
for a project locally. 

Note that dependencies are not installed at the top-level but within the
package directory. So if you do 'npm install express' then express's
dependencies will be installed in ./node\_modules/express/node\_modules directory.

You can specify package@version if you need a specific version. See
[https://github/com/isaacs/node-semver](https://github/com/isaacs/node-semver)
for details on semantic versioning names.

Use 'npm uninstall' to remove a package (include -g for global packages), and 
'npm update' to update a package.

For multiple packages use a package.json file, with (at least) "name", "version"
 and "dependencies" entries. Use "npm init" to create a skeleton package.json.
 Then use "npm install"/"npm update" to install/update all dependencies specified 
 in the file. You can use "npm install <package> —save" to install a new package 
 and add it to package.json at the same time.

To use modules, use require(). If you just specify a name, node will first look 
in the core modules folder, then the node_modules/module folder. Alternatively 
you can specify an absolute or relative path (the .js extension is not needed). 
You can load an entire folder with a single require() if that folder has a 
package.json file (the "main" module will be returned from require()).

# The Connect module

The Connect module builds on top of the http module, and allows the chaining of 
request handlers (e.g. for logging, static file handling, etc). Each handler 
has three arguments:

- req - the request object
- res - the response object
- next - the next handler in the chain

Here is a simple server:

    #!javascript
    var connect = require('connect');
    var app = connect();
    
    var logger = function(req, res, next) {
        console.log(req.method, req.url);
        next();  // chain to next handler
    }
    var helloWorld = function(req, res, next) {
        res.setHeader('Content-Type', 'text/plain');
        res.end('Hello world!');  // send the response body, no next chaining
    }
    
    // order is important when registering handlers
    app.use(logger);
    app.use(helloWorld);
    
    // If we wanted the response to only work when user navigates to
    // path /hello, we could have used:
    //  app.use('/hello', helloWorld);
    app.listen(8000);
    
    module.exports = app;  // optional, but useful to load module for tests

If this is in a file server.js, we can run it with 'node server' and access it at
http://localhost:8000

# Express web framework

[Express](http://expressjs.com/) is a node web framework built on top of Connect. 
Here is the same server as before written using Express:

    #!javascript
    var express = require('express');
    var app = express();
    
    app.use(function(req, res, next) {
       console.log(req.method, req.url);
       next();  // chain to next handler
    
    });
    // We can use app.use or specify a verb like get or post...
    app.get('/hello', function(req, res) {
        // res.send will set Content-Type automatically, but you can 
        // force JSON with res.json(). You can include an initial optional
        // first argument for the status code.
        res.send('Hello world!'); 
    });
    app.listen(8000);
    module.exports = app;

Request objects have methods to retrieve parameters, POST bodies, cookies,
etc, while the response objects have methods to set the status code, cookies,
headers, and do redirects.

