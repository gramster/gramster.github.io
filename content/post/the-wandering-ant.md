---
title: The Wandering Ant
date: 2010-01-03T19:29:00
author: Graham Wheeler
category: Math
slug: the-wandering-ant
comments: enabled
---

Imagine an infinite grid filled where each square is initially either
black or white. On this grid is an ant, which can face either north,
south, east or west. The ant moves over the grid according to the
following rules:

-   it it lands on a black cell it turns left 90 degrees; if it lands on
    a white cell it turns right 90 degrees
-   in each case the cell it just left changes color to its opposite
    (white to black or vice-versa)
<!-- TEASER_END -->

<img src="/img/image_thumb2.png" style="float:right;margin:10px" />

Running a computer simulation of this system, which was invented by
Christopher Langton in 1986, shows that after a while the ant gets stuck
in a cycle of 104 moves which move it two squares diagonally, after
which point it continues building this diagonal “highway”. It is
speculated that this will always occur (in which case we say that this
sequence is an *attractor* for the system), regardless of the initial
state of the grid, but so far no-one has been able to prove it (or the
opposite).

The diagram to the left shows what happens with an initial white grid
after 11,000 moves. The ant is the red pixel near the bottom right. Note
the diagonal highway moving down and to the right.

In 2000 it was shown that Boolean circuits (AND, OR, NOT) could be
created with the ant, and so the ant system is a universal computer or
Turing machine.

Some interesting extensions can be made to this system. For example,
more than two colors can be used, or more than one ant can be used (as
long as there are rules for what happens when they collide). Rules can
be added to make the ants reproduce. One of the simplest but most
interesting changes is to give the ant a color, and have the rules of
the system be extended to include changing the color of the ant, as well
as being dependent on the color of the ant (e.g. we could have the turn
rules behave as above if the ant is white but be reversed if the ant is
black). Such ants that have state are called *turmites*, and can
generate some very interesting patterns (originally these were named
tur-mites by A.K. Dewdney but Rudy Rucker shortened the name and his
version has stuck).

Further reading: [Professor Stewart's Cabinet of Mathematical
Curiosities](https://amzn.to/3sHb6Px)
has a short chapter where I first learned about Langton’s Ant, and
Stephen Wolfram discusses them briefly in a section on Turing machines
in his opus [A New Kind of
Science](https://amzn.to/3Hmon45).
