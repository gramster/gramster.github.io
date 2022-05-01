---
title: More on Pythagoras
slug: more-on-pythagoras
date: 2010-01-17T03:12:00
tags: 
category: Math
author: Graham Wheeler
comments: enabled
has_math: yes
---

Pythagoras is known for two great contributions to mathematics – he
established the need for formal proofs instead of just conjecture and
rules of thumb, and he established the existence of the irrationals. In
popular culture of course, Pythagoras is more well known for the
Pythagorean theorem – that the square of the hypotenuse of a right
angled triangle is the sum of the squares of the other two sides – but
this was one of the oldest known results in mathematics and in fact
predates Pythagoras by as much as a thousand years. Nonetheless,
Pythagoras provided a formal proof, and the result led him to ask
whether there were rational numbers that worked in the case where the
hypotenuse had the length two. That is, what was the fractional
representation of the square root of two? Pythagoras managed to show
there was none, leading to the discovery of the irrational numbers.

His proof was quite simple. Assume that \\(\sqrt{2}\\) can be
expressed as a fraction \\(\frac{a}{b}\\) of two whole
numbers \\(a\\) and \\(b\\). Assume these are the two smallest
such whole numbers – that is, they have no common divisor allowing the
fraction to be further reduced. Then:
<!-- TEASER_END -->

$$\frac{a^2}{b^2} = 2$$

so:

$$a^2 = 2 b^2$$

The right hand side is even, which means \\(a^2\\) is even, and
thus \\(a\\) must be even, or \\(a=2m\\) for some \\(m\\). But
then:

$${(2m)}^2 = 2b^2$$

so:

$$2m^2 = b^2$$

So the left hand side is even, and thus \\(b\\) must be even. But if
both \\(a\\) and \\(b\\) are even, then they have a common factor
2, which contradicts the assumption that they were the smallest such
numbers.

There are, of course, infinitely many cases where the Pythagorean
triangles have sides with rational length, and for that matter, integer
length. In a [recent
post](http://magimathics.com/more-on-diophantus-and-fermat)
I mentioned the method described by Diophantus that inspired Fermat’s
last theorem. It is easy to derive this method. Assume \\(a\\)
and \\(b\\) are relatively prime, and that \\(b\\) is odd. Then:

$${(a+b)}^2 = a^2 + b^2 + 2ab > a^2 + b^2 = c^2$$

Thus \\(c < a+b\\). So we can write \\(c = a+b-d\\) for some
positive \\(d\\). Then:

$$a^2 + b^2 = {(a+b-d)}^2 = a^2 + b^2 + d^2 + 2ab -2ad -2bd$$

So:

$$d^2 = 2ad + 2bd - 2ab$$

From this we can see \\(d\\) must be even. Let \\(d=2m\\); then:

$$4m^2 = 4am+4bm-2ab$$

So:

$$ab=2am+2bm-2m^2$$

Thus \\(ab\\) is even, and as we assumed \\(b\\) is odd, \\(
a\\) must be even. Since the sum of an even and an odd is an odd, \\(
c^2\\) must be odd and so \\(c\\) must be odd.

So \\(a\\) is even, and \\(b\\) and \\(c\\) are odd. We can
write \\(b=s-t\\) and \\(c=s+t\\) for some integers \\(s\\)
and \\(t\\). Then:

$$a^2 + {(s-t)}^2 = {(s+t)}^2$$

or:

$$a^2 + (s^2 - 2st + t^2) = (s^2 + 2st + t^2)$$

Simplifying:

$$a^2 = 4st$$

So \\(st\\) must be a perfect square. We can write \\(s=u^2\\)
and \\(t=v^2\\). Thus:

$$a^2 = 4u^2v^2$$

So:

$$a=2uv$$

So we have shown that a Pythagorean triple takes the form:

$$( 2uv, u^2-v^2, u^2 + v^2 )$$
