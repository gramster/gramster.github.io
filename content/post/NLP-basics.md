+++
title = "NLP Basics"
date = "2019-04-29T16:40:00"
author = "Graham Wheeler"
category = "Data Science"
comments = "enabled"
draft = "true"
tags = ["Python", "Jupyter", "Pandas", "Data Science", "Machine Learning"]
+++


*This is the fifth post in a series based off my [Python for Data Science bootcamp](https://github.com/gramster/pythonbootcamp). The other posts are:*

- *[a Python crash course](/post/python-crash-course/)*
- *[using Jupyter](/post/using-jupyter/)*
- *[exploratory data analysis](/post/exploratory-data-analysis-with-numpy-and-pandas/).*
- *[introductory machine learning](/post/basic-machine-learning/).*

In this post we will take a look at NLP - natural language processing - namely how we can apply ML techniques to collections of text (which we call _corpuses_ or maybe that should be _corpii_?).

We've touched on this topic before but will go in more detail here.

There are a number of applications for NLP, including:

- [sentiment analysis](https://en.wikipedia.org/wiki/Sentiment_analysis) - is the text saying positive or negative things? There are many reasons we may want to know this. A common use case is monitoring social media like Twitter and seeing if people are expressing positive or negative opinions about a company and how the trend is changing over time. If you're representing the company on social media, or you're trading the stock of the company, this is very useful info.
- [named-entity recognition (NER)](https://en.wikipedia.org/wiki/Named-entity_recognition) - what people, places and things are mentioned in the text?
- [topic modeling](https://en.wikipedia.org/wiki/Topic_model) or [text summarization](https://en.wikipedia.org/wiki/Automatic_summarization) - what is the text saying? Topic modeling is just broad classification - for example, "Is this text about sports?", while text summarization is trying to extract the most salient points from the text.
- [text generation](https://en.wikipedia.org/wiki/Natural-language_generation) - we can train models to generate text in different styles or on various topics
- auto-responder bots - combining some of the above techniques, we can build bots to do, for example, first-line product support

Before applying an NLP algorithm, we need to prepare the textual data. This includes a number of steps:

- _cleaning_ the data. If we are using word-level representation, we are going to want to map each word into a numeric representation (e.g. a vector), and to do this we would want to restrict ourselves in most cases to a finite set of allowable words (the _vocabulary_). In order to reduce the size of the vocabulary we typically will do some cleaning/preprocessing. This can include removing punctuation and "filler" words like "the" that aren't needed to understand the text; we call these _stop words_. We may also want to standardize the form of words to reduce the number of variations which we can do with _stemming_ and _lemmatization_.
- to represent text in a way amenable to ML algorithms, we need to encode it in some form of numeric vector. Depending on the algorithm, we may care about the order or the words, or in simple cases, perhaps we can simply use a set. In between these extremes we could have an unordered list of the words but with each word associated with some score for how important it is, or we could focus only on order for short sequences like adjacent word pairs (2-grams) or triplets (3-grams). If using a score, this could be as simple as the word count, or it could be a more sophisticated measure like the _TF_IDF_ score.

We'll discuss each of these further in the next sections.

## Python Libraries for NLP

The most well-known Python NLP library is the _Natural Language Toolkit_ or _NLTK_ (https://www.nltk.org/). This has been around for number of years and has well-written code that is great for teaching the concepts. It is not the most performant though, and focuses on classical approaches. More recently, spaCy (https://spacy.io/) has become popular, as it is a more modern library that is optimized for use in actual production environments.

Very recently there has been a plethora of new libraries, mostly based on PyTorch, such as:

- PyText (https://github.com/facebookresearch/PyText) from Facebook
- AllenNLP (https://allennlp.org/) from the Allen Institute for AI
- Flair (https://github.com/zalandoresearch/flair) from Zalando Research

For the purposes of this notebook we will stick to NLTK; once you understand the concepts it is not that difficult to transition to the other libraries.

A few other useful libraries are worth calling out; these aren't for NLP per-se but could be very handy if you are doing NLP:

- https://pypi.org/project/newspaper3k/ lets you extract articles from web sites into a structured form
- Wikipedia's Python library makes wikipedia access a breeze: https://wikipedia.readthedocs.io/en/latest/quickstart.html
- if you're dealing with parsing HTML data look at https://www.crummy.com/software/BeautifulSoup/


## Preparing the Text

### Removing Punctuation

Note that punctuation can be significant - think of the difference between ending a sentence with ! vs ? - but that most of the techniques used in NLP will ignore it. Character-level convolutional neural networks are one way of making use of punctuation.


```python
import sys
import unicodedata

punc = dict.fromkeys(i for i in range(sys.maxunicode) if unicodedata.category(chr(i)).startswith('P'))

data = [
    "I'll be there!",
    "N-o-o-o-o!!"
]
    
new_data = [s.translate(punc) for s in data]

new_data
```




    ['Ill be there', 'Noooo']



### Dealing with Letter Case

It's very common to normalize letter case when dealing with text (i.e. making everything upper case or lower case rather than mixed case). Whether you should do this and which case to use may depend on the context and the libraries you are using. For NLTK you generally want to use lower-case for everything.

A motivation for normalizing case is that the data we get is often dirty, with incorrect or mixed-capitalization, so normalizing at least makes it consistent. But we do lose information in the process, particularly to distinguish proper from regular nouns. 

### Tokenizing Words and Splitting Sentences


```python
# Install the prerequisites

import nltk


nltk.download('punkt')
```

    [nltk_data] Downloading package punkt to /Users/grwheele/nltk_data...
    [nltk_data]   Package punkt is already up-to-date!





    True




```python
from nltk.tokenize import word_tokenize

word_tokenize("The cat in the hat.")
```




    ['The', 'cat', 'in', 'the', 'hat', '.']




```python
from nltk.tokenize import sent_tokenize

data = "I will not eat them with a fox! I will not eat them in a box."

sent_tokenize(data)
```




    ['I will not eat them with a fox!', 'I will not eat them in a box.']




```python
[word_tokenize(s) for s in sent_tokenize(data)]
```




    [['I', 'will', 'not', 'eat', 'them', 'with', 'a', 'fox', '!'],
     ['I', 'will', 'not', 'eat', 'them', 'in', 'a', 'box', '.']]



Note that if we want to do sentence tokenization we should _not_ remove punctuation beforehand. Instead we could do something like:


```python
[word_tokenize(s.translate(punc)) for s in sent_tokenize(data)]
```




    [['I', 'will', 'not', 'eat', 'them', 'with', 'a', 'fox'],
     ['I', 'will', 'not', 'eat', 'them', 'in', 'a', 'box']]



### Stop-Word Removal and Restricting to a Fixed Vocabulary


```python
# Install the prerequisites

import nltk


nltk.download('stopwords')
```

    [nltk_data] Downloading package stopwords to
    [nltk_data]     /Users/grwheele/nltk_data...
    [nltk_data]   Package stopwords is already up-to-date!





    True




```python
from nltk.corpus import stopwords

stop = stopwords.words('english')

# NLTK assumes words have been lower-cased

data = "I will not eat them with a fox! I will not eat them in a box."
sentences = sent_tokenize(data)

[[w for w in word_tokenize(s.translate(punc).lower()) if w not in stop] for s in sentences]
```




    [['eat', 'fox'], ['eat', 'box']]



### Stemming and Lemmatization

Many similar words have common "stems". For example, "geology", "geological", "geologically" all have the stem "geolog". [Stemming](https://en.wikipedia.org/wiki/Stemming) is the process of reducing words to their stem forms - this reduces our vocabulary size with little loss of meaning. There are different algorithms for doing this; a common one is the Porter algorithm:


```python
from nltk.stem.porter import PorterStemmer

stemmer = PorterStemmer()

[stemmer.stem(w) for w in word_tokenize("geologically speaking the geology of the area is geological")]
```




    ['geolog', 'speak', 'the', 'geolog', 'of', 'the', 'area', 'is', 'geolog']



[Lemmatization](https://en.wikipedia.org/wiki/Lemmatisation) is reducing similar words to their dictionary form which is context-dependent (including part-of-speech). This is more complex than stemming, which is a function just of the word without the associated context).

Lemmatization is more complex that stemming and an area of open-research. It's also more accurate. So which one to use is dependent on the task at hand. For information retrieval tasks, recall may take priority over precision, so stemming can actually be better.

NLTK has a lemmatizer based on WordNet:



```python
# Install the prerequisites

import nltk

nltk.download('wordnet')
```

    [nltk_data] Downloading package wordnet to
    [nltk_data]     /Users/grwheele/nltk_data...
    [nltk_data]   Unzipping corpora/wordnet.zip.





    True




```python
from nltk.stem import WordNetLemmatizer

lemmatizer = WordNetLemmatizer()

[lemmatizer.lemmatize(w) for w in word_tokenize("geologically speaking the geology of the area is geological")]
```




    ['geologically',
     'speaking',
     'the',
     'geology',
     'of',
     'the',
     'area',
     'is',
     'geological']



You can see from the above that while stemming can reduce the size of the corpus vocabularly a decent amount, lemmatization does not do so quite as much. Here's a bigger example:


```python
# source: https://en.wikipedia.org/wiki/Natural-language_generation
data = """
Natural-language generation (NLG) is the natural-language processing task of 
generating natural language from a machine-representation system such as a 
knowledge base or a logical form. Psycholinguists prefer the term language 
production when such formal representations are interpreted as models for
mental representations.

It could be said an NLG system is like a translator that converts data into
a natural-language representation. However, the methods to produce the final
language are different from those of a compiler due to the inherent expressivity
of natural languages. NLG has existed for a long time but commercial NLG 
technology has only recently become widely available.

NLG may be viewed as the opposite of natural-language understanding: whereas
in natural-language understanding, the system needs to disambiguate the input
sentence to produce the machine representation language, in NLG the system 
needs to make decisions about how to put a concept into words.

A simple example is systems that generate form letters. These do not typically
involve grammar rules, but may generate a letter to a consumer, e.g. stating
that a credit card spending limit was reached. To put it another way, simple 
systems use a template not unlike a Word document mail merge, but more complex 
NLG systems dynamically create text. As in other areas of natural-language 
processing, this can be done using either explicit models of language (e.g.,
grammars) and the domain, or using statistical models derived by analysing
human-written texts."""

tokens = word_tokenize(data)
print(f"{len(tokens)} tokens")
print(f"{len(set(tokens))} unique tokens")
print(f"{len(set([stemmer.stem(w) for w in tokens]))} unique stems")
print(f"{len(set([lemmatizer.lemmatize(w) for w in tokens]))} unique lemmas")
```

    260 tokens
    152 unique tokens
    137 unique stems
    145 unique lemmas


### Labeling Parts of Speech

In many cases we won't concern ourselves with parts of speech (POS); we will simply take our sequence of cleaned up words and turn that into a vector representation, which we will discuss in the next section. However, POS tagging can be helpful in disambiguating words that can have multiple meanings and grammatical purposes based on context. For example:

- "Look at the time"
- "Time how long it took to look"

So for some models we can do POS labelling and then encode the POS tags as part of the model input.


```python
# Install the prerequisites
import nltk

nltk.download('averaged_perceptron_tagger')
```

    [nltk_data] Downloading package averaged_perceptron_tagger to
    [nltk_data]     /Users/grwheele/nltk_data...
    [nltk_data]   Unzipping taggers/averaged_perceptron_tagger.zip.





    True




```python
from nltk import pos_tag, word_tokenize

pos_tag(word_tokenize("Look at the time. Time how long it took to look."))
```




    [('look', 'NN'),
     ('at', 'IN'),
     ('the', 'DT'),
     ('time', 'NN'),
     ('.', '.'),
     ('time', 'NN'),
     ('how', 'WRB'),
     ('long', 'JJ'),
     ('it', 'PRP'),
     ('took', 'VBD'),
     ('to', 'TO'),
     ('look', 'VB'),
     ('.', '.')]



All the different tags are described in the NLTK help which we can access with:


```python
import nltk


nltk.download('tagsets')
nltk.help.upenn_tagset()
```

    [nltk_data] Downloading package tagsets to
    [nltk_data]     /Users/grwheele/nltk_data...


    $: dollar
        $ -$ --$ A$ C$ HK$ M$ NZ$ S$ U.S.$ US$
    '': closing quotation mark
        ' ''
    (: opening parenthesis
        ( [ {
    ): closing parenthesis
        ) ] }
    ,: comma
        ,
    --: dash
        --
    .: sentence terminator
        . ! ?
    :: colon or ellipsis
        : ; ...
    CC: conjunction, coordinating
        & 'n and both but either et for less minus neither nor or plus so
        therefore times v. versus vs. whether yet
    CD: numeral, cardinal
        mid-1890 nine-thirty forty-two one-tenth ten million 0.5 one forty-
        seven 1987 twenty '79 zero two 78-degrees eighty-four IX '60s .025
        fifteen 271,124 dozen quintillion DM2,000 ...
    DT: determiner
        all an another any both del each either every half la many much nary
        neither no some such that the them these this those
    EX: existential there
        there
    FW: foreign word
        gemeinschaft hund ich jeux habeas Haementeria Herr K'ang-si vous
        lutihaw alai je jour objets salutaris fille quibusdam pas trop Monte
        terram fiche oui corporis ...
    IN: preposition or conjunction, subordinating
        astride among uppon whether out inside pro despite on by throughout
        below within for towards near behind atop around if like until below
        next into if beside ...
    JJ: adjective or numeral, ordinal
        third ill-mannered pre-war regrettable oiled calamitous first separable
        ectoplasmic battery-powered participatory fourth still-to-be-named
        multilingual multi-disciplinary ...
    JJR: adjective, comparative
        bleaker braver breezier briefer brighter brisker broader bumper busier
        calmer cheaper choosier cleaner clearer closer colder commoner costlier
        cozier creamier crunchier cuter ...
    JJS: adjective, superlative
        calmest cheapest choicest classiest cleanest clearest closest commonest
        corniest costliest crassest creepiest crudest cutest darkest deadliest
        dearest deepest densest dinkiest ...
    LS: list item marker
        A A. B B. C C. D E F First G H I J K One SP-44001 SP-44002 SP-44005
        SP-44007 Second Third Three Two * a b c d first five four one six three
        two
    MD: modal auxiliary
        can cannot could couldn't dare may might must need ought shall should
        shouldn't will would
    NN: noun, common, singular or mass
        common-carrier cabbage knuckle-duster Casino afghan shed thermostat
        investment slide humour falloff slick wind hyena override subhumanity
        machinist ...
    NNP: noun, proper, singular
        Motown Venneboerger Czestochwa Ranzer Conchita Trumplane Christos
        Oceanside Escobar Kreisler Sawyer Cougar Yvette Ervin ODI Darryl CTCA
        Shannon A.K.C. Meltex Liverpool ...
    NNPS: noun, proper, plural
        Americans Americas Amharas Amityvilles Amusements Anarcho-Syndicalists
        Andalusians Andes Andruses Angels Animals Anthony Antilles Antiques
        Apache Apaches Apocrypha ...
    NNS: noun, common, plural
        undergraduates scotches bric-a-brac products bodyguards facets coasts
        divestitures storehouses designs clubs fragrances averages
        subjectivists apprehensions muses factory-jobs ...
    PDT: pre-determiner
        all both half many quite such sure this
    POS: genitive marker
        ' 's
    PRP: pronoun, personal
        hers herself him himself hisself it itself me myself one oneself ours
        ourselves ownself self she thee theirs them themselves they thou thy us
    PRP$: pronoun, possessive
        her his mine my our ours their thy your
    RB: adverb
        occasionally unabatingly maddeningly adventurously professedly
        stirringly prominently technologically magisterially predominately
        swiftly fiscally pitilessly ...
    RBR: adverb, comparative
        further gloomier grander graver greater grimmer harder harsher
        healthier heavier higher however larger later leaner lengthier less-
        perfectly lesser lonelier longer louder lower more ...
    RBS: adverb, superlative
        best biggest bluntest earliest farthest first furthest hardest
        heartiest highest largest least less most nearest second tightest worst
    RP: particle
        aboard about across along apart around aside at away back before behind
        by crop down ever fast for forth from go high i.e. in into just later
        low more off on open out over per pie raising start teeth that through
        under unto up up-pp upon whole with you
    SYM: symbol
        % & ' '' ''. ) ). * + ,. < = > @ A[fj] U.S U.S.S.R * ** ***
    TO: "to" as preposition or infinitive marker
        to
    UH: interjection
        Goodbye Goody Gosh Wow Jeepers Jee-sus Hubba Hey Kee-reist Oops amen
        huh howdy uh dammit whammo shucks heck anyways whodunnit honey golly
        man baby diddle hush sonuvabitch ...
    VB: verb, base form
        ask assemble assess assign assume atone attention avoid bake balkanize
        bank begin behold believe bend benefit bevel beware bless boil bomb
        boost brace break bring broil brush build ...
    VBD: verb, past tense
        dipped pleaded swiped regummed soaked tidied convened halted registered
        cushioned exacted snubbed strode aimed adopted belied figgered
        speculated wore appreciated contemplated ...
    VBG: verb, present participle or gerund
        telegraphing stirring focusing angering judging stalling lactating
        hankerin' alleging veering capping approaching traveling besieging
        encrypting interrupting erasing wincing ...
    VBN: verb, past participle
        multihulled dilapidated aerosolized chaired languished panelized used
        experimented flourished imitated reunifed factored condensed sheared
        unsettled primed dubbed desired ...
    VBP: verb, present tense, not 3rd person singular
        predominate wrap resort sue twist spill cure lengthen brush terminate
        appear tend stray glisten obtain comprise detest tease attract
        emphasize mold postpone sever return wag ...
    VBZ: verb, present tense, 3rd person singular
        bases reconstructs marks mixes displeases seals carps weaves snatches
        slumps stretches authorizes smolders pictures emerges stockpiles
        seduces fizzes uses bolsters slaps speaks pleads ...
    WDT: WH-determiner
        that what whatever which whichever
    WP: WH-pronoun
        that what whatever whatsoever which who whom whosoever
    WP$: WH-pronoun, possessive
        whose
    WRB: Wh-adverb
        how however whence whenever where whereby whereever wherein whereof why
    ``: opening quotation mark
        ` ``


    [nltk_data]   Unzipping help/tagsets.zip.


If you look at our test above you may notice the tagger didn't do that well. In the first sentence "look" is a verb but was tagged as a noun. Your mileage will vary with different libraries when applying many NLP algorithms; understanding natural language is a hard problem and has not been completely solved!

## Text Representation

Once we have our cleaned and canonicalized data, we need to turn it into a form suitable for consumption by an ML algorithm; i.e. as a vector of features. In this section we'll look at common ways of doing this.

In most cases we need a vocabulary; that is, the complete set of words that we expect to see in our problem domain. We'll typically generate this from the training data, and then as part of our data prep for prediction, we will drop any new words that we did not see before and are not in our vocabulary. That means if we are working in a domain that changes frequently we should retrain often, to make our vocabularly reflect current usage.


### Bag of Words

One of the simplest representations is to use a frequency count vector to represent our input as a set of words across the vocabularly domain. We saw an example of this in the previous notebook. We repeat that here with slight refinement to remove stop words:


```python
data = [
    "the cat sat on the mat",
    "the mat belonged to the rat",
    "the hat was on the mat",
    "the cat ate the rat",
    "the cat now has the hat",
    "cat hat, cat mat, no rat"
]

import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer

v = CountVectorizer(stop_words="english")
X = v.fit_transform(data)
pd.DataFrame(X.toarray(), columns=v.get_feature_names())
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>ate</th>
      <th>belonged</th>
      <th>cat</th>
      <th>hat</th>
      <th>mat</th>
      <th>rat</th>
      <th>sat</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>5</th>
      <td>0</td>
      <td>0</td>
      <td>2</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
    </tr>
  </tbody>
</table>
</div>



You can see the total vocabulary from the column names:

`ate belonged cat hat mat rat sat`

and each row simply has a count in the corrresponding column of the number of times that word occurred in the sentence. Notice that by using this encoding approach we lose all order information.

Be aware that as our corpus grows large, so does our vocabulary, and we can end up with very sparse vectors. There are ways of dealing with this but they introduce other limitations. Take a look at the `HashingVectorizer` as one possibility.

### 1-Hot Encoding

1-hot encoding (sometimes called 1-Hot or 1HE) is a similar represenation to Bag of Words except we use binary 0/1 instead of frequency counts. Another way of thinking of this is that Bag of Words is a multiset represenation of the sentence while 1-hot is a normal set. We just need to add a `binary=True` argument to the `CountVectorizer` constructor for this behavior:


```python
v = CountVectorizer(stop_words="english", binary=True)
X = v.fit_transform(data)
pd.DataFrame(X.toarray(), columns=v.get_feature_names())
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>ate</th>
      <th>belonged</th>
      <th>cat</th>
      <th>hat</th>
      <th>mat</th>
      <th>rat</th>
      <th>sat</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>5</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
    </tr>
  </tbody>
</table>
</div>



You'll notice a problem with the above examples; while we could specify stop words we didn't get to do stemming. In order to fix this we need to do some customization of the vectorizer:


```python
class StemmedCountVectorizer(CountVectorizer):
    _stemmer = nltk.stem.PorterStemmer()
    
    def build_analyzer(self):
        analyzer = super(StemmedCountVectorizer, self).build_analyzer()
        return lambda doc: [StemmedCountVectorizer._stemmer.stem(w) for w in analyzer(doc)]

```


```python
v = StemmedCountVectorizer(stop_words="english", binary=True)
X = v.fit_transform(data)
pd.DataFrame(X.toarray(), columns=v.get_feature_names())
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>ate</th>
      <th>belong</th>
      <th>cat</th>
      <th>hat</th>
      <th>mat</th>
      <th>rat</th>
      <th>sat</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
    </tr>
    <tr>
      <th>5</th>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
    </tr>
  </tbody>
</table>
</div>



### Word Significance Metrics

The problem with word counts, especially if we don't remove stop words, is that common words get scored highly, which may not always be desirable. What we want to score highly are words that are common *in this instance* that are not common *across all instances*. That should weight words that are significant to the particular row/instance. We can do this with *[Term Frequency - Inverse Document Frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)* or TF-IDF scores. 

- _Term frequency_ is the frequency of each word (term) in the input; i.e. this is the same as the bag-of-words score we saw above, but scaled by the number of words in each sentence
- _Document frequency_ is a measure of how common the term is across all instances; e.g. it could be the percentage of input instances that contain the term
- _Inverse document frequency_ is a reciprocal measure of document frequency. It is typically the log of the reciprocal of the document frequency, with 1 added to the numerator and denominator to avoid divide-by-zero issues, and 1 added to the total to avoid zero-weighting IDFs.

For example, let's say we have two sentences in our corpus D:

```
D = { "cats like rats", "rats don't like cats" }
```

Then our vocabulary is:

```
V = { "cats", "don't", "like", "rats" }
```

and our term frequencies are:

```
tf("cats", "cats like rats") = 1 / 3
tf("don't", "cats like rats") = 0
tf("like", "cats like rats") = 1 / 3
tf("rats", "cats like rats") = 1 / 3
tf("cats", "rats don't like rats") = 1 / 4
tf("don't", "rats don't like cats") = 1 / 4
tf("like", "rats don't like cats") = 1 / 4
tf("rats", "rats don't like cats") = 1 / 4
```

while our document frequencies are:

```
df("cats", D) = 2
df("don't", D) = 1
df("like", D) = 2
df("rats", D) = 2
```

and our inverse document frequencies are:

```
idf("cats", D) = 1 + log(3 / (1 + df("cats", D))) = 1 + log(3 / 3) = 1
idf("don't", D) = 1 + log(3 / (1 + df("don't", D))) = 1 + log(3 / 2) = 1.176
idf("like", D) = 1 + log(3 / (1 + df("like", D))) = 1 + log(3 / 3) = 1
idf("rats", D) = 1 + log(3 / (1 + df("rats", D))) = 1 + log(3 / 3) = 1
```

(Note: the numerator is 3 as we have two "documents" and we add 1). You can see here that the word "don't" gets a higher score than the other words which is expected as it is the only workd that doesn't occur in both sentences.

Then our TF-IDF scores are:

```
tf-idf("cats", "cats like rats", D) = tf("cats", "cats like rats") * idf("cats", D) = 1/3 * 1 = 1/3
tf-idf("don't", "cats like rats", D) = tf("don't", "cats like rats") * idf("don't", D) = 0 * 1.176 = 0
tf-idf("like", "cats like rats", D) = tf("like", "cats like rats") * idf("like", D) = 1/3 * 1 = 1/3
tf-idf("rats", "cats like rats", D) = tf("rats", "cats like rats") * idf("rats", D) = 1/3 * 1 = 1/3
tf-idf("cats", "rats don't like rats", D) = tf("cats", "rats don't like cats") * idf("cats", D) = 1/4 * 1 = 1/4
tf-idf("don't", "rats don't like cats", D) = tf("don't", "rats don't like cats") * idf("don't", D) = 1/4 * 1.176 = 0.294
tf-idf("like", "rats don't like cats", D) = tf("like", "rats don't like cats") * idf("like", D) = 1/4 * 1 = 1/4
tf-idf("rats", "rats don't like cats", D) = tf("rats", "rats don't like cats") * idf("rats", D) = 1/4 * 1 = 1/4
```

From this you can see:

- the word "don't" has no significance in the first sentence and higher-than average significance in the second sentence
- the other words have the same weight in their respective sentences, but overall higher weight in the first sentence simply because it is shorter

It's worth noting that second point because intuitively the word "like" should have the same score in both sentences, so TF-IDF scores are useful for identifying significant words within inputs but should be used with care when comparing significance across inputs.

To do this in sklearn:


```python
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer

data2 = [
    "cats like rats",
    "rats don't like cats",
]
v = TfidfVectorizer()
X = v.fit_transform(data2)
pd.DataFrame(X.toarray(), columns=v.get_feature_names())
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>cats</th>
      <th>don</th>
      <th>like</th>
      <th>rats</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>0.577350</td>
      <td>0.000000</td>
      <td>0.577350</td>
      <td>0.577350</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0.448321</td>
      <td>0.630099</td>
      <td>0.448321</td>
      <td>0.448321</td>
    </tr>
  </tbody>
</table>
</div>



Note that we see the same relative pattern but the scores are different to what we computed. `sklearn` does some additional normalization of scores which you can read about [here](https://scikit-learn.org/stable/modules/feature_extraction.html#tfidf-term-weighting).

TF-IDF is a very commonly used approach to computing word salience scores. A more recent approach is "contextual salience" which you read about in [this paper](https://arxiv.org/abs/1803.08493).

### Ordered Representation with n-grams, Character or Word Vector Sequences

Works well if we have a finite length input - e.g. Twitter tweets. For unbounded text we would need to feed this in to our algorithm in chunks, so would need an approach that has some form of "short-term memory" like an LSTM NN.

## Classification Models using Classical Techniques

If we have a limit on the size of the input sentences, we can use traditional techniques to build classifiers. A great example is Twitter with its 240 character limit. The main problem is the sparsity of the data.


In reality we are often dealing with larger pieces of text and may have very variable size. In this case we typically are going to want to use neural network techniques where we can feed in the input using some form of sliding window and can use short-term memory (e.g. LSTM) for remembering prior context.


## Named Entity Recognition (NER)

## Sentiment Analysis

## Topic Modeling

## Chatbots

## Generative Models


```python

```
