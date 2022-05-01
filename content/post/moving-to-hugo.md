---
title: Moving my blog to Hugo
author: Graham Wheeler
date: 2022-04-30
---

I have been using Nikola for about the past 8 years for my blog, but have been
eyeing the development of Hugo and thinking I might want to migrate, and have
finally done it. There's nothing wrong with Nikola; I think it's actually less
work than Hugo because it handles `.ipynb` Jupyter notebooks very seamlessly,
but Hugo is super-fast so you can work in a 'live-releoad' mode which I like.
So this weekend I finally did it. I didn't take notes as I went, but I think
I can reconstruct what I did feairly easily:

First I installed Hugo:

```
brew install hugo
```

Then I created a new site:

```
hugo new site grahamwheeler --format yaml
cd grahamwheeler
git init .
```

I decided to use YAML as I am familiar with it, unlike TOML, and I think it is
trivial to change later. 

I then looked at the themes on https://themes.gohugo.io/. There are way too
many options, but it seems it is fairly easy to switch later, so I picked 
[Clean White](https://themes.gohugo.io/themes/hugo-theme-cleanwhite/) as
I liked the simple look and it had most of what I wanted. I added it with:


```
cd themes
git clone https://github.com/zhaohuabing/hugo-theme-cleanwhite.git
```

Then I took the sample config at `hugo-theme-cleanwhite/exampleSite/config.toml' and converted it to YAML with an online converter, and edited it to fit my 
settings, putting the result in the top level directory. At this point I could 
run:

```
hugo serve
```

and see my basic site.

Next I copied over my old posts to the `content/post` folder. They already had
YAML front matter and most of that was compatible with what Hugo uses. I did 
have to clean up the date fields to put them in either yyyy-mm-dd or
yyyy-mm-ddThh:mm:ss format, as Hugo seems much more fussy than Nikola when
it comes to date parsing. Also, Nikola used `status: draft` for yet-to-be-published
drafts, while Hugo uses `draft: true`.

I also copied over my image files to the `static/img` folder. I had to change 
all the image URL references to be have an `/img/' prefix for Hugo to find them.
But at this point I already has a largely working site.

I did use Kramdown's CSS customization on a lot of my images, to make them float
left or right so text would wrap around them.
That isn't supported by the Markdown system Hugo uses, so I 
changed a bunch of image references to plain HTML img elements with style 
attributes.

I also use MathJax quite frequently. That wasn't working, but the fix was quite
simple; in the theme folder I needed to edit `layouts/partial/footer.html`, 
and add:

```
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.9/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>
```

In the same file,, immediately afterwards, I also added the script tag for
utterances, which I use for comments now (recently moved from Disqus):

```
<script src="https://utteranc.es/client.js"
        repo="gramster/gramw.github.io"
        issue-term="title"
        theme="github-light"
        crossorigin="anonymous"
        async>
</script>
```

Some of my posts are in the form of Jupyter notebooks. Those were a bit more
work with Hugo. Nikola is notebook-aware and does the processing itself, but
Hugo does not. I found a wrapper around `nbconvert`, [nb2hugo](https://github.com/vlunot/nb2hugo/) which does a decent job. In Nikola the front matter went into
separate `.meta` files; I had to inline that as an initial cell in the notebooks
and change the format to TOML (this inconsistency will likely drive me to use
TOML everywhere soon). For now the process of coverting the notebooks is manual
which isn't ideal but doesn't need to happen too often. I put all the notebooks 
in a folder named `notebooks`, and created a script in the same folder called
`convert.sh`, with the contents:

```
#!/bin/bash

for i in *.ipynb
do
    nb2hugo "$i" --site-dir .. --section post
done
```

I will just need to run that every time I change a notebook.

That's about all that was needed to migrate. I'm pretty happy with the result.
I expect there will be some rough edges but probably nothing too serious. 


```



