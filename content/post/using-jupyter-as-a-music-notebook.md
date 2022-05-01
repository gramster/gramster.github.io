+++
title = "Using Jupyter as a Music Notebook"
author = "Graham Wheeler"
date = "2016-02-27T20:00:00"
tags = ["Python", "Jupyter", "Music"]
+++


I recently started playing guitar again after a long absence and wanted to start making some notes in a digital form. Unfortunately, I didn't find any good tools. There is TeX of course, which can do anything, but I was hoping for something a bit more WYSIWYGy. There are some very good tools available for musical scores (MuseScore, Frescobaldi), but I want something that is more like a traditional notebook with lots of notes interspersed with occasional musical notation (in both traditional and tablature forms).

So an obvious potential candidate is Jupyter (nee IPython), but it has no support for musical notation out of the box. But it is doable and in this post I'll walk through how I got it to work on my Mac. This is also my first attempt at using a Jupyter notebook as my blog post in Nikola so I'm kiling two birds with one stone.

Note: the original version of this post was written when getting this to work required getting a bleeding edge copy of Abjad and patching a bug; this is no longer required and I have updated the (now much shorter) post accordingly.
<!-- TEASER_END -->

I want something that is fairly easy to write the music in. MusicXML isn't too bad, except XML. What little I've seen of Liyponds markup looked pretty unfriendly for the simple use cases I have. A few days ago I stumbled across a Python library called abjad which looked just the ticket. As I write this I have it working for music on the staff but not tablature (I'm not sure it supports that) but I hope by the end of this post I'll have that figured out too!

Next we need to install Abjad. You should ideally do this in a virtual environment. I use Anaconda and already have one set up, so can do the installation as follows; you may need to prefix this with `sudo` depending on your setup.



```bash
%%bash
pip install abjad abjad-ext-ipython
```

Lilypond is needed for rendering, and to have MIDI output recorded in the notebook, fluidsynth is needed. This requires Homebrew or MacPorts on a Mac. I have [Homebrew](https://brew.sh/) so I do the installation with:


```bash
%%bash
brew install fluidsynth lilypond
```

Now we should be able to load Abjad, as follows:


```python
%load_ext abjadext.ipython
```

and test it:


```python
from abjad import *
```


```python
duration = Duration(1, 4)
notes = [Note(pitch, duration) for pitch in range(8)]
staff1 = Staff(notes)
show(staff1)
```


![svg](output_9_0.svg)


Success! But what about tablature? It turns out that Lilypond uses a variant of Staff called TabStaff for tablature. Abjad does not have a TabStaff class but does allow you to override the tag used for a staff with a `lilypond_type` argument:


```python
notes = [Note(pitch, duration) for pitch in range(8)]
staff2 = Staff(notes, lilypond_type='TabStaff')
show(staff2)
```


![svg](output_11_0.svg)


You can combine these by putting them in a `Score`:


```python
show(Score([staff1, staff2]))
```


![svg](output_13_0.svg)


If you're wondering why I recreated the notes list for `staff2` instead of reusing those from `staff1` the explanation is [here](https://github.com/Abjad/abjad/issues/1038).

