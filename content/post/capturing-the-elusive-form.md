---
title: Capturing the Elusive Form
date: 2007-01-29T03:50:00
author: Graham Wheeler
category: Programming
slug: capturing-the-elusive-form
---

Last night I decided to try write a web browser that has the ability to
take screen captures. I have an
[rss2book](http://www.mobileread.com/forums/showthread.php?t=7946)
program that I wrote for my [Sony
Reader](http://www.sonystyle.com/is-bin/INTERSHOP.enfinity/eCS/Store/en/-/USD/SY_DisplayProductInformation-Start?ProductSKU=PRS500U2)
which has been great at producing PDF content from the web (mostly RSS
but it is not limited to that). However, I figured that for some
content, especially that which is largely Javascript driven, it might be
better to capture the full content of a web page as an image and then
turn that into a [DJVu](http://www.djvuzone.org/) document (the Sony
Reader doesn't actually support DJVu, but I imagine that there will be
e-book readers soon that do - or at the least there's always the Nokia
N800).

Essentially, this app needs to do the following:
<!-- TEASER_END -->

-   host the AxWebBrowser Active/X control
-   have a 'Capture' button that, when clicked, will grab the entire
    page as an image and write it to a JPEG file

The first part is easy. The second part involves a couple of steps:

-   resizing the host form so that the full page fits with no scroll
    bars
-   somehow grabbing the contents of this form

It took a little while to figure out hwo to solve the first problem, but
once you know it's easy:

    IHTMLDocument2 doc = (IHTMLDocument2)webBrowser.Document;
    IHTMLElement2 body = (IHTMLElement2)doc.body;
    this.Width += (body.scrollWidth - webBrowser.Width);
    this.Height += (body.scrollHeight - webBrowser.Height);

However, the second problem is really hard. I already had some code I'd
written which does window captures. The problem is that if the window is
obscured or clipped anywhere it gets no content for that area. Given
that I am typically resizing the form to have a height much larger than
my display's physical resolution I'm almost always going to have
clipping occur.

In .Net 2.0 there is an alternative, namely
<font face="Courier">Control.DrawToBitmap</font>. That actually works
wonderfully for WinForms controls - but it does not draw anything for
Active X controls (or at least not for AxWebBrowser). My understanding
is that the control must be able to handle WM\_PRINT messages, although
I'm not entirely convinced of this explanation, because it is
inconsistent with my experience with
<font face="Courier">PrintWindow</font> (see below).

I tried calling <font face="Courier">RaisePaintEvent</font> on the form
and passing in a Graphics object created from a bitmap - but that
doesn't work either. Only the form is drawn, not any of the child
controls (so all you really get in most cases is a blank image with a
border).

I tried P/Invoking <font face="Courier">PrintWindow</font> from
user32.dll, but that suffers from the same clipping problem that my
original window grabbing code has. So I'm still stumped here. Watch this
space to see if I find a solution. In the meanwhile, if you don't have
Active/X controls to worry about, I recommend
<font face="Courier">Control.DrawToBitmap</font>; it is simple and works
well.

*Update:* I found my code that accesses the ActiveX control broke with
IE7. I rewrote it using the Windows.Forms.WebBrowser classes in .Net
2.0. They work fine. There is still no Control.DrawToBitmap though,
presumably because these classes are just wrapping the underlying
ActiveX control.
