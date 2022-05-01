---
title: Cute Math Curiosity
date: 2008-05-06T05:27:00
author: Graham Wheeler
category: Math
slug: cute-math-curiosity
---

I heard this proof a couple of days back and thought it was fun and
elegant. If you draw a circle anywhere on the surface of the earth there
will be at least two opposite points that have the same temperature.

The proof relies on [Bolzano's
theorem](http://mathworld.wolfram.com/BolzanosTheorem.html), which is an
instance of the [Intermediate Value
Theorem](http://mathworld.wolfram.com/IntermediateValueTheorem.html).
Bolzano's theorem says that if a continuous function defined on an
interval is sometimes
[positive](http://mathworld.wolfram.com/Positive.html) and sometimes
[negative](http://mathworld.wolfram.com/Negative.html), it must be 0 at
some point.

We assume that temperature on any path on the earth's surface is
continuous. If *f(x)* is a continuous function, and *g(x)* is a
continuous function, [then *f(x)-g(x)* is also
continuous](http://mathworld.wolfram.com/ContinuousFunction.html).

So, choose some starting point on the circumference of the circle, and
let f(x) be the temperature at the point at offset x clockwise from the
starting point, and let *g(x)* be the temperature at the point opposite
that point. If the temperature at some point x is warmer than at its
opposite point x', then *f(x)*-*g(x)* is positive, while *f(x')*-*g(x')*
is negative. So, by Bolzano, there is a point where *f(x)*-*g(x)*=0,
i.e. *f(x)*=*g(x)*.
