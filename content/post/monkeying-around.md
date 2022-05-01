---
title: Monkeying Around
date: 2009-12-13T19:03:00
tags: 
category: Math
author: Graham Wheeler
comments: enabled
has_math: yes
---

After a huge storm blew up, the ship foundered. Dawn’s light found just
six survivors washed up on a desert island – five men and one monkey.
The men spent the day gathering all the food they could find – which was
just a pile of coconuts. After a dinner of coconut milk and flesh, the
exhausted men decided to they would divide the remaining coconuts up the
following day, before splitting up and exploring the remainder of the
island.

During the night one man woke up and started worrying about whether
there would be a disagreement in the morning over the coconuts. He
decided to take his share, and divided the coconuts equally into five.
There was one left over which he gave to the monkey, then he took his
share and hid them away, before going back to
sleep.
<img src="/img/image_thumb6.png" style="float:right;margin:10px" />
<!-- TEASER_END -->

A little later the next man woke up, and had the same fear. He too
divided the coconuts into five, and had one left over that he gave to
the monkey, before hiding his share and going back to sleep. And so the
night went on, with each man waking up, dividing the remaining coconuts
in five, hiding one share and giving the one extra to the monkey.

In the morning, the men awoke and divided the remaining coconuts, which
came out to five equal shares. No-one said anything about the missing
coconuts as each thought he had been the first to hide a share and was
thus the best off.

How many coconuts were there in the beginning?

It is not difficult to express this problem as a set of equations; what
makes the equations hard to solve is that the solutions must be
integers. Such equations are called Diophantine equations, after the 3rd
century AD’s Diophantus of Alexandria, who was the first known
algebraist to examine equations limited to rational number solutions. We
know little of Diophantus himself other than the following puzzle left
after his death:

-   his childhood lasted 1/6 of his life
-   he grew a beard after another 1/12
-   after 1/7 more he married
-   5 years later he had a son
-   the son lived to half Diophantus’ age
-   and Diophantus died 4 years later

From this we can determine how long Diophantus lived, how long his
boyhood lasted, what age he grew a beard, what age he got married, when
he had a son, and how long his son lived.
<img src="/img/monkey_thumb1.png" style="float:right;margin:10px" />


Diophantus’ great work, The Arithmetica, is a text on computational
arithmetic rather than theoretical mathematics, closer to the
mathematics of Egypt, Babylon and India than to Greece. Diophantus
promised 13 books in his introduction but only ten are known, with four
only being discovered recently in an Arabic manuscript found in Iran.
The earliest commentaries on The Arithmetica were written by Hypatia,
the first known Western female mathematician, who was brutally murdered
by a mob of Christian fanatics in 415 AD as they burned Alexandria’s
great library to the ground and destroyed much of the world’s repository
of classical knowledge.

Many people are familiar with Fermat’s famous “Last Theorem”; it was in
the margins of a copy of Diophantus’ Arithmetica (Book 2, problem 8 ),
in which Diophantus describes how to find solutions to 
\\(x^{2}+y^{2}=z^{2}\\) for a given value of \\(z\\), that Fermat
wrote his famous note asserting that there are no solutions to equations
of this form for any powers higher than two, and that “For this I have
discovered a truly wonderful proof, but the margin is too small to
contain it.”

Going back to the coconuts, if we call the initial number of
coconuts \\(x\\) and the number hidden away by each man as \\(a,
b, c, d, e\\) respectively, and the number of coconuts each sailor got on
the next day as \\(y\\), we get this set of equations:

$$x = 5a + 1$$
$$4a = 5b + 1$$
$$4b = 5c + 1$$
$$4c = 5d + 1$$
$$4d = 5e + 1$$
$$4e = 5y$$

We can use successive substitutions to reduce this to a single equation
in two unknowns. The first sailor took \\(\frac{1}{5}(x-1)\\)
coconuts, and left \\(4\frac{1}{5}(x-1) = \frac{4}{5}(x-1)\\)
coconuts. The second sailor then took
\\(\frac{1}{5}(\frac{4}{5}(x-1)-1) = \frac{4x-9}{25}\\) coconuts and
left \\(\frac{4x-9}{25} = \frac{16x-36}{25}\\) coconuts. Continuing
in this way we can find that the number of coconuts left by the third,
fourth and fifth sailors were \\(\frac{64x-244}{125}\\),
\\(\frac{256x-1476}{625}\\), and \\(\frac{1024x-8404}{3125}\\)
respectively. Therefore:

$$\frac{1024x-8404}{3125} = 5y$$

or:

$$1024x = 15625y + 8404$$

Normally, for real numbers, we would need two equations in two unknowns,
but because we know the solutions must be integers the possible answers
are more constrained. Equations of the form:

$$ax + by = c$$

are known as linear Diophantine equations; in our case
\\(a=1024\\), \\(b=-15625\\) and \\(c=8404\\), and we have:

$$1024x - 15625y = 8404$$

If \\(a\\) and \\(b\\) have a common denominator, then clearly for
the equation to have integer solutions \\(c\\) must also be a
multiple of this common denominator.; if it is not, then there are no
integer solutions. So we can simplify a linear Diophantine equation by
dividing the coefficients of x and y, and the constant, by their
greatest common denominator (GCD). The coefficients are then relatively
prime, the gcd is 1 and no further simplification can be done.

Assuming we can simplify to the point where we have co-prime
coefficients and still have an integer constant, we will have solutions
– in fact, an infinity of them. This is quite easy to show. Assume we do
have two solutions, \\((x_{1},y_{1})\\) and
\\((x_{2},y_{2})\\). Then:

$$a x_{1} + b y_{1} = c = a x_{2} + b y_{2}$$

and so:

$$a(x_{1}-x_{2}) = b(y_{2}-y_{1})$$

So the difference between two solutions for \\(x\\) must satisfy:

$$x_{1}-x_{2} = \frac{b}{a}(y_{2}-y_{1})$$

If \\(g\\) is the GCD of \\(a\\) and \\(b\\), then we can
divide both \\(a\\) and \\(b\\) on the right hand side by
\\(g\\) to get a coprime numerator and denominator:

$$x_{1} - x_{2} = \frac{\frac{b}{g}}{\frac{a}{g}} (y_{2} - y_{1})$$

Because \\(\frac{b}{g}\\) and \\(\frac{a}{g}\\) are coprime, the
smallest \\((y_{2}-y_{1})\\) that can expand the right hand side
out to an integer value is:

$$y_{2}-y_{1} = \frac{a}{g}$$

And similarly:

$$x_{1}-x_{2} = \frac{b}{g}$$

So we have an infinite number of solutions of the form:

$$x = x_{1} - \frac{b t}{g}$$

$$y = y_{1} + \frac{a t}{g}$$

The problem usually comes down to finding the smallest pair of positive
integers that satisfy the equation.

To solve a linear Diophantine equation such as the one above, we can
apply Euclid’s method for finding the GCD of the coefficients (which
will be 1, as our coefficients are coprime, but we are interested in the
steps anyway):

$$15625 = 15 \times 1024 + 265\\\\
 1024 = 3 \times 265 + 229 \\\\
 265 = 1 \times 229 + 36 \\\\
 229 = 6 \times 36 + 13 \\\\
 36 = 2 \times 13 + 10 \\\\
 13 = 1 \times 10 + 3 \\\\
 10 = 3 \times 3 + 1$$

Note how the coefficients on the left of the right hand side match those
in the continued fraction:

$$\begin{align}
\frac{15625}{1024} & = 15 + \frac{265}{1024}\\\\
                   & = 15 + \frac{1}{\frac{1024}{265}}\\\\
                   & = 15 + \frac{1}{3 + \frac{229}{265}}\\\\
                   & = 15 + \frac{1}{3 + \frac{1}{\frac{265}{229}}}\\\\
                   & = 15 + \frac{1}{3 + \frac{1}{1 + \frac{36}{229}}}\\\\
                   & = 15 + \frac{1}{3 + \frac{1}{1 + \frac{1}{\frac{229}{36}}}} \\\\
                   & = 15 + \frac{1}{3 + \frac{1}{1 + \frac{1}{6 + \frac{13}{36}}}} \\\\
                   & \ldots\\\\
                   & = 15 + \frac{1}{3 + \frac{1}{1 + \frac{1}{6 + \frac{1}{2 + \frac{1}{1 + \frac{1}{3 + \frac{1}{3}}}}}}} \\\\
                   & = \langle 15; 3, 1, 6, 2, 1, 3, 3 \rangle
\end{align}$$

We can invert the steps to get a solution. Starting at the bottom:

$$10 = 3 \times 3 + 1 \Rightarrow 1 = 10 - 3 \times 3$$

We keep expanding this, working backwards, and substituting the
equations we have derived above for the remainders:

$$\begin{align}
1 & = 10-3\times 3 \\\\
  & = 10-3\times(13-1\times 10) \\\\
  & = 4\times 10-3\times 13 \\\\
  & = 4\times(36-2\times 13)-3\times 13 \\\\
  & = 4\times 36-11\times 13 \\\\
  & = 4 \times 36-11 \times ( 229-6 \times 36 ) \\\\
  & = 70 \times 36-11 \times 229 \\\\
  & = 70 \times ( 265-1 \times 229 )-11 \times 229 \\\\
  & = 70 \times 265-81 \times 229 \\\\
  & = 70 \times 265-81 \times ( 1024-3 \times 265 ) \\\\
  & = 313 \times 265-81 \times 1024 \\\\
  & = 313 \times ( 15625-15 \times 1024 )-81 \times 1024 \\\\
  &  = 313 \times 15625-4776 \times 1024
\end{align}$$

So we have determined that \\(x=-4776\\) and  \\(y=-313\\) is a
solution of \\(1024x-15625y=1\\). This is all very well but how do we
adjust this for the fact that the \\(c\\) value we actually care
about is 8404, not 1? Simple! We just have to multiply each side by 8404
to get a solution to our original equation, namely \\(x=-4776
\times 8404 = -40137504\\) and  \\(y=-313 \times 8404 = -2630452\\).

We know from earlier that the general solution of our equation has the
form:

$$x = -40137504 + 15625 t$$

$$y = -2630452 + 1024 t$$

It’s easy to see we have our first positive solution at \\(t=2569\\),
namely \\(x= 3121\\) and  \\(y=204\\). So there were 3121 coconuts
originally, and on the last division each sailor got 204 coconuts.

A variant of this problem has there being a single coconut left on the
final day as well. In this case there is a very clever trick that can be
used, which uses the fact that if we add four coconuts to the original
pile it is evenly divisible by 5. If we allow the use of *negative*
coconuts it is easy to see that –4 is a solution. In this case, the
first sailor divides the pile into 5 negative coconuts, gives one
positive coconut to the monkey, and returns four negative coconuts to
the pile, so there are once again –4 coconuts! Each sailor repeats the
same process, always leaving –4 coconuts. To get to the first positive
solution we just need to observe that since we divide the pile into 5
six times, each successive solution must be \\(5^{6} = 15625\\)
larger than the last, so the first solution is 15621.

This variant appeared in a short story by Ben Ames Williams that ran in
the Saturday Evening Post in October 1926. Williams did not include the
answer, and the Post’s offices were flooded with letters, to the point
where the editor sent Williams a wire: “For the love of Mike, how many
coconuts? Hell popping around here”. Williams continued to receive
letters requesting the answer for the next twenty years!

Further reading:

I first heard this problem, and learnt the method of continuous
fractions, as a high school student when doing an extra-curricular math
class at the University of the Witwatersrand’s Schmerenbeck Center (so
long ago Diophantus may still have been alive).  Martin Gardner’s
[Colossal Book of
Mathematics](https://amzn.to/32LAfNS)
discusses this problem in the first chapter, along with some unorthodox
and general solutions. Steven Hawking’s book [God created the
Integers](https://amzn.to/3EEukHG)
includes annotated excerpts from The Arithmetica, and some biographical
material. Clifford Pickover’s [The Math
Book](https://amzn.to/3z8g09s)
includes a chapter on Hypatia.
