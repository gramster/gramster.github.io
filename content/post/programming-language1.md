+++
title = "Implementing a Programming Language Part 1"
date = "2019-04-30T20:10:00"
author = "Graham Wheeler"
category = "Programming"
comments = "enabled"
draft = "true"
+++


# Implementing a Programming Language pt 1

This is the first in a series of posts about implementing programming languages. In this post I'll talk about the common basic phases of building a simple expression interpreter. I'll keep fleshing this out in further posts. My ambition is to go all the way to designing a new programming language and implementing a compiler for it. We'll see if I get there :-)

I've implemented a number of compilers and virtual machines over the years and taught a graduate class in the subject several times. That was a long time ago (30 years) and I can't say I've kept up with developments but I still think this could be a fun project and an education series of posts.

I'll start by using Python as the implementation language but I'd like to get to the point where I have a self-hosted language compiler: that is, my language should be rich enough and sufficiently implemented that it can have it's own compiler written in it.

That will take some time. In this post I'm just going to cover the basics, with a simple expression calculator that supports variables.

## The NotVeryExpressionist Language

Here are some examples of the kind of programs that can be written in our simple language:

    let radius = ARG1
    let pi = 3.1415927
    pi * radius * radius

## Defining a Grammar

The syntax of languages are usually defined by _formal grammars_. These were pioneered by Noah Chomsky. A _Chomsky Grammar_ or _Phrase Structure Grammar_ is a 4-tuple \\((T, N, P, Z)\\) where \\(T\\) is a set of _terminal_ symbols, \\(N\\) is a set of _non-terminal_ symbols, \\(P\\) is a set of _productions_, and \\(Z\\) is a start symbol. The _vocabulary_ of the grammar is the union of \\(N\\) and \\(T\\), and the _language_ is the set of all possible sequences of terminal symbols that can be produced from the prroductions starting from the start symbol. Put another way, the language is the (usually infinite) set of all possible syntactically correct programs defined by the grammar.

For our simple language, we can use the production rules below:

    program ::= statement_list
    statement_list ::= statement | statement statement_list
    statement ::= assignment | expression
    assignment ::= 'let' IDENTIFIER '=' expression
    expression ::= add_expression
    add_expression ::= mult_expression '+' add_expression | mult_expression '-' add_expression
    mult_expression ::= term '*' mult_expression | term '/' mult_expression
    term ::= IDENTIFIER | NUMBER
        
Here, `program` is the start symbol, all the characters or character sequences in quotes are terminals, as are `IDENTIFIER` and `NUMBER`, while all the lower-case words on the left side of the production rules are non-terminals. `|` is an `or` operator and has lowest precedence. The rules above are written in a form called Backus-Naur form, or BNF (although I dropped the typical `<>` around non-terminal names).

You can read this informally as:

_A program is a statement list. A statement list is either a statement, or a statement followed by a statement list. A statement is either an assignment or an expression. An assignment starts with the non-terminal `let`, followed by an IDENTIFIER, an `=`, and finally an `expression`..._

etc.

Some things to note:

- we use the `let` keyword as the first token in an assignment distinguish an assignment from an expression. I intentionally did this to simplify our implementation. 
- we use various specializations of `expression` (`add_expression`, `mult_expression`) to reflect operator precedence.

Sometimes BNF is enhanced with regular expression-like operators, so the rule for `statement_list` might be written as any of:

    statement_list ::= statement [statement_list]
    statement_list ::= statement statement_list*
    statement_list ::= statement+

Looking at the most of these variants, its clear that `statement_list` is defined recursively. In this particular case the recursion is on the right-hand end of the production rule. We could also have written:

    statement_list ::= [statement_list] statement

The first is what we call "right-recursive" as it refers to itself recursively with the rightmost element, while the second is "left recursive". 
You will see later that depending on how we implement our language parser, this difference can be important and we sometimes have to rewrite our grammar in a different recursive form to be able to implement it.
Some languages can only be easily expressed using one of these forms; they're not always easily interchangeable like here. For us, we will use a "recursive descent" parser, which reflects the grammar rules. In such a parser we always want to make some forward progress in the program before we recurse, so we avoid left-recursion where we could recurse infinitely with no progress.

In general, whitespace is not considered significant; this is true in many languages (although not in Python). We usually assume that symbols in the grammar can be separated by arbitrary amounts of whitespace.

You'll notice we never defined `IDENTIFIER` or `NUMBER`. These are terminals, but we can still define them with production rules. The difference now is that whitespace is not allowed unless it is explicitly defined:

    IDENTIFIER ::= LETTER_OR_UNDERSCORE LETTER_OR_UNDERSCORE_OR_DIGIT*.
    NUMBER ::= ['-'] DIGIT+ [ '.' DIGIT*.
    LETTER_OR_UNDERSCORE ::= LETTER | '_'.
    LETTER_OR_UNDERSCORE_OR_DIGIT ::= LETTER | DIGIT | '_'.
    LETTER ::= 'A' | ... | 'Z' | 'a' | ... | 'z'.
    DIGIT ::= '0' | ... | '9'.

The terminal symbols that are character sequences in most languages can't be used as identifiers; these are called "reserved words". In our language the only reserved word is `let`.

We'll use `ARGn` as a special set of identifiers for the command line arguments.

## Tokenizing a Program




```python
def next_token(expect=None):
    global token, pos, line, col
    if expect and token != expect:
        raise Exception(f"Expected {expect} at {line}:{col}")
    # skip whitespace
    while pos < len(text) and text[pos].isspace():
        if text[pos] == '\n':
            col = 0
            line += 1
        else:
            col += 1
        pos += 1
        
    if pos == len(text):
        token = None
        return
    
    startpos = pos
    
    if text[pos].isdigit():
        while pos < len(text) and (text[pos].isdigit() or text[pos] == '.'):
            pos += 1
    elif text[pos].isalpha():
        while pos < len(text) and text[pos].isalnum():
            pos += 1
    else:
        pos += 1
            
    token = text[startpos:pos]
    col += pos - startpos
                           
```


```python
text = """
    let radius = ARG1
    let pi = 3.1415927
    pi * radius * radius
"""

pos = 0
line = 1
col = 0

while True:
    next_token()
    print(f"{line}:{col} {token}")
    if not token:
        break
```

    2:7 let
    2:14 radius
    2:16 =
    2:21 ARG1
    3:7 let
    3:10 pi
    3:12 =
    3:22 3.1415927
    4:6 pi
    4:8 *
    4:15 radius
    4:17 *
    4:24 radius
    5:0 None


## Implementing the Parser


```python
def number():
    next_token()

def identifier():
    next_token()
    
def term():
    if not token:
        raise Exception(f"Premature end of program at {line}:{col}!")
    elif token[0] == '-':
        next_token()
        number()
    elif token[0].isdigit():
        number()
    else:
        identifier()
    
def assignment():
    next_token('let')
    identifier()
    next_token('=')
    expression()
    
def mult_expression():
    term()
    if token == '*' or token == '/':
        next_token()
        mult_expression()
   
def add_expression():
    mult_expression()
    if token == '+' or token == '-':
        next_token()
        add_expression()
        
def expression():
    add_expression()
    
def statement():
    if token == 'let':
        assignment()
    else:
        expression()
    
def statement_list():
    statement()
    if token:
        statement_list()

def program(body):
    global pos, text, token, line, col
    text = body
    line = 1
    pos = 0
    col = 0
    token = None
    next_token()
    statement_list()
```


```python
p = """
    let radius = ARG1
    let pi = 3.1415927
    pi * radius * radius
"""

program(p)
```

### Evaluating Expressions


```python
def number():
    value = float(token)
    next_token()
    return value
    
def identifier():
    if token in context:
        value = context[token]
    else:
        raise Exception(f"Undefined variable {token} at {line}:{col}")
    next_token()
    return value

def term():
    if not token:
        raise Exception(f"Premature end of file at {line}:{col}!")
    elif token[0] == '-':
        next_token()
        value = -number()
    elif token[0].isdigit():
        value = number()
    else:
        value = identifier()
    return value
    
def assignment():
    global context
    next_token('let')
    varname = token
    next_token()
    # Note - we don't use identifier() as LHS and RHS have different meaning.
    next_token('=')
    value = expression()
    context[varname] = value
    return value
    
def mult_expression():
    value = term()
    if token == '*':
        next_token()
        value *= mult_expression()
    elif token == '/':
        next_token()
        value /= mult_expression()
    return value
            
def expression():
    value = mult_expression()
    if token == '+':
        next_token()
        value += expression()
    elif token == '-':
        next_token()
        value -= expression()
    return value
    
def statement():
    if token == 'let':
        value = assignment()
    else:
        value = expression()
    return value
    
def statement_list():
    value = statement()
    if token:
        value = statement_list()
    return value

def program(body, arguments=None):
    global pos, text, token, line, col, context
    text = body
    line = 1
    pos = 0
    col = 0
    token = None
    context = {}
    if arguments:
        context = {f'ARG{i+1}': v for i, v in enumerate(arguments)}
    nexttoken()
    value = statement_list()
    print(f"Last value: {value}")
```


```python
program(p, arguments=[5])
```

    Last value: 78.5398175



```python
context
```




    {}




```python

```


```python

```
