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
I can reconstruct what I did fairly easily:

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
TOML everywhere soon). For now the process of converting the notebooks is manual
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

Publishing is a bit more messy. I host using github-pages, and Nikola has a 
command that will check my sources into one branch and the generated site into 
another branch and push everything upstream, easy as pie. Hugo doesn't seem 
to have anything like this so it's all a bit of a kludge.

First I renamed my old repo `gramw.github.io` and created a new one with the 
same name, and pushed all the content. Then I created a `gh-pages` empty 
branch (I'm not sure this was necessary; it may have happened anyway, but I
was having some permission problems as I worked this out and wanted to eliminate
this as a source of problems):

```
git checkout --orphan gh-pages
git reset --hard
git commit --allow-empty -m "Initializing gh-pages branch"
git push -u origin gh-pages
git checkout main
```

I put the two script elements that I was patching in to the `footer.html` in a `patch/footer.html` file:

```
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.9/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>
<script src="https://utteranc.es/client.js"
        repo="gramster/gramw.github.io"
        issue-term="title"
        theme="github-light"
        crossorigin="anonymous"
        async>
</script>
```

and the command line I used to convert the notebooks in a file `patch/convertnb.sh`:

```
#!/bin/bash

for i in notebooks/*.ipynb
do
    nb2hugo "$i" --site-dir . --section post
done
```

Then I created a Github action do generate the content whenever I push to `main` and push that content to the `gh-pages` branch:

```
name: Github Pages
on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-18.04
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
          submodules: true

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true

      - name: Patch theme
        run: |
          cat patch/footer.html themes/hugo-theme-cleanwhite/layouts/partials/footer.html > footer.html
          mv footer.html themes/hugo-theme-cleanwhite/layouts/partials
          sed -i  's/CATALOG/SECTIONS/' themes/hugo-theme-cleanwhite/layouts/_default/single.html
        shell: bash

      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: "3.9"

      - name: Install nb2hugo
        run:
          python -m pip install nb2hugo
        shell: bash

      - name: Convert notebooks
        run: patch/convertnb.sh
        shell: bash

      - name: Build
        run: hugo --minify --baseURL=https://www.grahamwheeler.com

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public


```

And that's it! It's a reasonable solution.


