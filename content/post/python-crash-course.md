+++
title = "A Python Crash Course"
date = "2018-04-12T20:10:00"
updated = "2018-05-05"
author = "Graham Wheeler"
category = "Programming"
comments = "enabled"
tags = ["Python", "Programming"]
+++


I've been teaching [a crash course in data science with Python](https://github.com/gramster/pythonbootcamp), which starts off with learning Python itself. The target audience is Java programmers (generally senior level) so its assumed that things like classes and methods are well understood. The focus is mostly on what is different with Python. I teach it using Jupyter notebooks but the content is useful as a blog post too so here we go.

The other parts are:

- *[using Jupyter](/post/using-jupyter/)*
- *[exploratory data analysis](/post/exploratory-data-analysis-with-numpy-and-pandas/).*
- *[introductory machine learning](/post/basic-machine-learning/).*

## Introduction

### Python's Origins

Python was conceived in the late 1980s, and its implementation began in December 1989 by Guido van Rossum at Centrum Wiskunde & Informatica (CWI) in the Netherlands as a successor to the ABC language. It takes its name from Monty Python's Flying Circus.

Python is a dynamic language but is strongly typed (i.e. variables are untyped but refer to objects of fixed type).
<!-- TEASER_END -->

> ### How Python Evolves
> 
> Python evolves in a fairly straightforward way, more-or-less like this:
> 
> - people propose changes by writing *Python Enhancement Proposals* ([PEPs](https://www.python.org/dev/peps/))
> - the Python core committee will assign a 'dictator' who will decide whether the PEP is worthy of becoming part of the standard, and if so it does, after some amount of discussion and revision
> - disagreements are finally settled by the Python Steering Council, a 5-person elected body of volunteers that at the time of writing includes Guido van Rossum, Python's inventor and the 'Benevolent Dictator for Life' (BDFL)
> 
> An important standard PEP is the Style Guide, [PEP-8](https://www.python.org/dev/peps/pep-0008/). By default, PyCharm will warn of any PEP-8 violations. There are external tools such as [flake8](https://gitlab.com/pycqa/flake8) that can be used to check code for compliance in other environments, or you can use a code formatter like [Black](https://github.com/ambv/black). 

### StackOverflow is your friend!

For Python questions and Python data science questions, make use of [StackOverflow](https://stackoverflow.com/questions/tagged/python). Pay attention to comments on suggested answers; the "accepted answer" is often not the best. Look for comments about whether it is the "most Pythonic". Python has an idiomatic style different to many other languages and so a novice coming from another language will often accept an answer that is closer to idiomatic in that other language rather than Python.

Also, if you're struggling to understand some code in your early days with Python, you may find this '[execution visualizer](http://pythontutor.com/)' helpful.


### "Batteries Included"

Python is often described as having "batteries included". This is a reference to the rich set of libraries (packages)included in the standard distribution as well as the vast collection of freely available packages that can be used to bootstrap your development. Or, as Randall Munroe puts it:

![](https://imgs.xkcd.com/comics/python.png)

There are many thousands of Python packages available, often giving you many choices for similar purposes. One way to find quality packages is to look the curated lists at https://python.libhunt.com/ and https://awesome-python.com/

### What Editor/IDE Should I Use?

Python is increasingly popular as a first programming language. It is very easy to pick up the basics, but is still a rich and powerful language that can serve expert programmers too. This post assumed you are familiar with some other OOP language so its not a great place to start if you're a real beginner. I suggest going to [PythonTutor](http://pythontutor.com/) which is a web-based environment that has lots of examples, great support tools, and links to a number of online course and other resources. From this point on I assume you are a proficient software developer but new(ish) to Python.

Many IDEs and editors have support for Python usually through plugins. If you are already using an editor or IDE for some other language and it supports Python too, that's probably the best option. Examples are Atom, Visual Studio Code, Visual Studio, Atom, Sublime Text, and PyCharm. My personal go-to these days is Visual Studio Code, but you should use whatever works for you.

### Python 2.7 or Python 3.x?

Easy: all new projects should be Python 3.6 or later. Python 2.7 is the end of the 2.x line and will be end-of-lifed on Jan 1, 2020. Unless you really need it for some legacy code, forget about Python 2.

### Installing Python

If you're going to be doing data science, my recommendation used to be to use the [Anaconda distribution of Python](https://www.anaconda.com/download/#macos). It comes with most of the packages you will need ready to use. If you don't need all of those extras you could install the [stripped-down "Miniconda" version](https://conda.io/miniconda.html). I suggest that you install for yourself only, which on Mac or Linux will put the installation in a subdirectory of your home directory. You can read more about installing Anaconda [here](https://conda.io/docs/user-guide/install/index.html).

However, these days you can install pre-compiled binaries through the standard `pip` package installer, and there is very little need for Anaconda anymore; Anaconda also has a very brittle environment activation system that seems to keep changing and so doesn't always place nice when you're trying to run and debug code directly from your editor. I no longer believe it is the best choice. The advantages have largely disappeared while the disadvantages have grown.

Note that Macs come with Python already installed. As of Catalina they come with Python 3. It used to be that to didn't want to mess with the system-supplied Python on Macs in case you ended up breaking something. I don't know if this is still an issue, but to be safe consider instead installing Python using [Homebrew](https://brew.sh/).

On Windows you can now just type "python" in a command shell window and you will be taken to the Windows Store from where you can install Python. 

On Linux, you can use your system package manager to install Python if it isn't already present.

If you prefer to get Python from the source, then on a Mac or Windows you should download and install from [here](https://www.python.org/downloads/). On Linux, follow the instructions [here](http://docs.python-guide.org/en/latest/starting/install3/linux/).

You may need to update your path to point to the right location. On Windows/Linux this likely isn't an issue, but if you installed Python on mac from Homebrew, you'll want to make sure that gets picked up earlier in your path than the system one. That might mean adding:

    export PATH=/usr/local/bin:$PATH
    
to your ~/.zshrc file (assuming Catalina and so using zsh as your shell).

## Python docs

https://docs.python.org/3/ has very detailed documentation.

Most Python packages have good documentation at https://readthedocs.org/

If you use Python a lot on a Mac you may find [Dash](https://kapeli.com/dash) useful; it is a utility that gives you fast access to context-sensitive help for many libraries.

That said, Python has a help() function that is very useful.

The [Hitchhiker's Guide](http://docs.python-guide.org/en/latest/) is a very useful, extremely comprehensive opinionated guide that will be helpful to beginners.


## Using the REPL

To start the REPL (read-execute-print loop, or interactive interpreter), just type `python` at the command line.

Use the `help()` function to read the documentation for a module/class/function. As a standalone invocation, you enter the help system and can explore various topics.

Python scripts are stored in plain text files with `.py` extensions. You can run the script `foo.py` at the command line by invoking:

    python foo.py
    
When you do so the Python interpreter will compile the script to an intermediate bytecode, and the result will be stored in a file with the same base name and a `.pyc` extension. As an optimization, the interpreter will look to see if a `.pyc` file with a more recent file modification date exists when you invoke it to run a script and use that if it does. In Python 2.x these files were saved alongside the Python source files but in Python 3.x they are stored in a subdirectory named `__pycache__`.

> ### A better REPL: bpython
> 
> [bpython](https://www.bpython-interpreter.org/) is an alternative REPL that adds a number of useful features at the command line, like syntax highlighting and auto-completion. 
> 
> You can install with `pip install bpython`.
> 
> If you're going to use the command line repl I recommend it, although there are other options too that I haven't tried:
> 
> - ptpython https://github.com/jonathanslenders/ptpython
> - DreamPie http://dreampie.sourceforge.net/
> 
> Yet another alternative to the REPL, of course, is Jupyter.
> 
> For the hard-core Pythonista, you can replace your entire shell with one based on Python; see http://xon.sh/.

## Quickstart - A Simple Example

Before diving into the details, let's look at a simple Python script to get a quick taste of what's to come. We're not going to go into details here but have annotated the code with some comments and if you are familiar with other object-oriented languages this should be quite easy to understand. Some things that may be unusual to you:

- No braces; in Python whitespace is significant. This can take some getting used to if you come from a C-family language but isn't as bad as it seems once you do.
- Instance methods require an explicit "this" argument which in Python by convention is called `self` . Because it is explicit you could call it something else, but just don't :-).
- Static methods have a `@staticmethod` decorator.
- The class constructor - of which there can only be one - is called `__init__`.
- Docstrings are specified using actual string literals inline rather than in comments.
- The method to convert to string is named `__str__` not `toString`.
- String formatting is done using embedded code in {} and preceding the string with 'f' (this is new to Python 3.6); e.g. `print(f'Hello, {name}!')`.


```python
import math  # import math module
from IPython.display import SVG, display

"""
A simple turtle graphics example that produces SVG output that can
be displayed in Jupyter.
"""

class Turtle:
    " Turtle graphics drawing to SVG path "  # class docstring
    
    DEG2RAD = math.pi/180  # class level variable
    
    @staticmethod
    def deg2rad(d):  # static method
        """ Convert degrees to radians """
        return d * Turtle.DEG2RAD
    
    def __init__(self):  # class constructor; "self" is like "this"
        # We don't declare instance variables explicitly in Python; we simply
        # assign values to them during construction. In this case we will
        # do all of that in the reset() method.
        self.reset()
        
    def reset(self):
        self.draw = True  # instance variable
        self.path = "M0,0 "
        self.x = self.y = 0
        self.turnto(0.0)
    
    def turnto(self, angle):
        " Turn to absolute angle. "
        self.angle = angle % 360.0
        self.dx = math.sin(Turtle.deg2rad(self.angle))
        self.dy = math.cos(Turtle.deg2rad(self.angle))
        
    def right(self, angle):
        " Relative turn "
        self.turnto(self.angle + angle)

    def left(self, angle):
        self.right(angle)
        
    def up(self):
        self.draw = False
        
    def down(self):
        self.draw = True
        
    def move(self, distance):
        " Relative move by distance "
        self.x = int(distance * self.dx)
        self.y = int(distance * self.dy)
        self.path += f"{'l' if self.draw else 'm'}{self.x},{self.y} "

    def moveto(self, x, y):
        " Absolute move to (x, y)"
        self.x = x
        self.y = y
        self.path += f"{'L' if self.draw else 'M'}{self.x},{self.y} "
        
    def svg(self):
        return '<svg id="doc" xmlns="http://www.w3.org/2000/svg" ' +\
            'version="1.1" width="500" height="500"><path d="' +\
            self.path +\
            '" stroke="green" fill="none" vector-effect="non-scaling-stroke" /></svg>'
            
    def __str__(self):
        " Convert to string representation. "
        return f"Turtle at {self.x},{self.y} facing {self.angle}"

            
def swisscross(turtle, level):  # top-level function
    " Swiss cross is a space filling curve. "
    if level >= 0:
        swisscross(turtle, level - 1)
        t.right(90)
        swisscross(turtle, level - 1)
        t.move(10)
        swisscross(turtle, level - 1)
        t.right(90)
        swisscross(turtle, level - 1)
        

t = Turtle()  # create class instance; note no 'new' 
t.up()
t.moveto(20, 30)
t.turnto(315)
t.down()
swisscross(t, 5)
t.move(10)
swisscross(t, 5)

# Display the result using SVG
display(SVG(t.svg()))
        
# final state

print(t)
```


![svg](output_6_0.svg)


    Turtle at -7,-7 facing 315.0


## Installing pip

TODO

## Creating Virtual Environments

TODO - fix up and go into details

When starting a Python project, you want to first create a *virtual environments* - pseudo-installations of Python and the supporting packages that use links instead of physical files, that point to appropriate versions. We won't do that here, but it is worth knowing about, and it is a recommended best practice when starting a new application. You can also use this to create a Python 2 environment after installing Python 3, and vice-versa.

For Conda: https://conda.io/docs/using/envs.html

For pip: https://packaging.python.org/guides/installing-using-pip-and-virtualenv/

If you are not in a Conda environment, the recommended practice now is to use the virtual environment manager `pipenv`: http://docs.python-guide.org/en/latest/dev/virtualenvs/. `pipenv` did not play nice with Conda until recently but it appears that may be fixed now; you can read more at https://docs.pipenv.org/advanced/#pipenv-and-other-python-distributions.


## Installing Third-Party Packages

Once you have created and activated a virtual environment you can start to populate it with packages (you could do this globally and not in a virtual environment but that is not recommended; you can sometimes get into ['dependency hell'](https://en.wikipedia.org/wiki/Dependency_hell) and you'll be much happier if that happens in a virtual environment you can  just discard rather than your global environment. Furthermore, you may have projects that depend on different versions of the same package which is not a problem with virtual environments but not possible if you install packages globally).

The standard way to install packages is with `pip install`. However, if you have installed `conda` you should use `conda install` first and only if that fails use `pip install`. Conda has a smaller set of packages which is why it doesn't always succeed, but the ones it does have have been built for Conda so installing that way is preferred.

Use `conda uninstall` or `pip uninstall` to remove packages.

To see what packages are installed use `pip freeze`.

When installing packages with pip or conda you can specify the version number; e.g.:

    pip install ipython=6.3.1
    
There's a lot more to package management than this but this is enough for most of what you will do.

> If you really want to get into the details; [this is a great blog post](https://pydist.com/blog/pip-install) that gets into the details of what is happening under the hood when you run `pip install`.

## Python is an OOPL

Python is a pure object-oriented language. Operators like `+` are simply methods on a class. The Python interpreter will convert an infix operator to an instance method call.

For example, there is an `int` class for integers. There is an `__add__` method defined on that class for addition. So:    


```python
3 + 4
```




    7



is the same as:


```python
(3).__add__(4)
```




    7



The double underscore in Python is called *dunder* and is used extensively internally; `__add__` is called a *dunder-method*. Dunder-methods are important to understand if you want to take full advantage of Python hence this early introduction.

You can see the methods on a class by using the `dir` function, for example `dir(int)`.

We will discuss how to define new classes later. A key takeaway here is that this use of dunder-methods allows us to override many operators simply by overriding the associated dunder-method. Two particularly useful ones are `__str__` (cast to string) and `__repr__` (cast to text representation); these are typically the same for a class but need not be. For example, notice the differences here:


```python
a = "abc"
print(a.__str__())  # Equivalent to str(a)
print(a.__repr__())
```

    abc
    'abc'


While it is true that Python is an OOPL in that everything is an object, Python does not impose OOP on you, unlike many other OOPLs. As you have seen so far, you can simply write and run one or more statements or expressions. Your code might consist of some top level statements and functions. There is no need to encapsulate everything explicitly inside a class. In that regard, Python can be considered a multi-paradigm language. You can write your code in an imperative, an object-oriented, or even, to some extent, a functional manner.

## Indentation and Comments

Python does not use {} for demarcating blocks of code; instead it uses indentation. This distinguishes it from most other programming languages and can take some getting used to. In particular, it requires care when pasting code in an editor (most Python editors are smart about this but other editors are not). The reason for this choice is that Guido originally designed Python as a teaching language and favored readability.

The convention in Python is to indent with spaces, not tabs (this avoids tab settings causing misinterpretation of code). Indentation standard is 4 spaces at a time, although some companies have different conventions (usually 2, if not 4).

Comments start with # and continue to the end of the line. By convention if # is used on the same line as code it should be preceded by at least two spaces.

## Simple Functions

Python named functions are defined with `def`:


```python
def add(a, b):
    return a + b

add(2, 3)
```




    5




```python
add("cat", "hat")  # This is entirely legitimate; + concatenates strings
```




    'cathat'




```python
add("cat", 3)  # This is not allowed; Python typecasting must almost always be explicit
```


    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-7-94b2f852ae18> in <module>()
    ----> 1 add("cat", 3)  # This is not allowed; Python typecasting must almost always be explicit
    

    <ipython-input-5-1315785ad0b1> in add(a, b)
          1 def add(a, b):
    ----> 2     return a + b
          3 
          4 add(2, 3)


    TypeError: must be str, not int


### import

Python code is packaged in the form of _packages_ consisting of one of more _modules_. A module is a single Python file, while a package is a directory of Python modules containing an additional `__init__.py` file, to distinguish a package from a directory that just happens to contain a bunch of Python scripts. The `__init__.py` file can be empty, but often contains code which is executed upon the initial import of a module in the package.

You install a package with `pip` or `conda`. Once installed, to use the package you must import it. You can also import modules although this is less common. 

There are several common ways of importing. Let's say we want to import a package `foo` that defines a class `Widget`:

* `import foo` will import the `foo` package; any reference to modules/classes/functions will need to be prefixed with `foo.`; e.g. `foo.Widget`
* `import foo as bar` will import the `foo` package with the alias `bar`; any reference to modules/classes/functions will need to be prefixed with `bar.`; e.g. `bar.Widget`
* `from foo import Widget` can be used to import a specific module/class/function from `foo` and it will be available as `Widget`
* `from foo import *` will import every item in `foo` into the current namespace; this is bad practice, don't do it.

When resolving an import, the Python interpreter will look for it in (in-order):

- the directory from which the main script was run
- the list of directories specified by the `PYTHONPATH` environment variable, if any
- the directories used for packages including in the Python installation

You can see the full set of directories that will be searched by looking at the `sys.path` variable:


```python
import sys

sys.path
```




    ['',
     '/Users/gram/anaconda/lib/python36.zip',
     '/Users/gram/anaconda/lib/python3.6',
     '/Users/gram/anaconda/lib/python3.6/lib-dynload',
     '/Users/gram/.local/lib/python3.6/site-packages',
     '/Users/gram/anaconda/lib/python3.6/site-packages',
     '/Users/gram/anaconda/lib/python3.6/site-packages/aeosa',
     '/Users/gram/anaconda/lib/python3.6/site-packages/IPython/extensions',
     '/Users/gram/.ipython']



If the module being imported cannot be found, an `ImportError` exception will be raised. This gives a safe way to do importing of optional modules:


```python
try:
    import nonexistent
except ImportError:
    print('Please install the nonexistent module!')
```

    Please install the nonexistent module!


Imports don't have to happen at the top level; they can be done within the bodies of functions. This enables lazy/just-in-time importing and can help speed up initial load time of scripts. 

### Writing a main function and handling command line arguments

The `sys` module lets us access command line arguments as `sys.argv:

```python
    #!/usr/bin/python

    import sys

    def main():
        # print command line arguments
        for arg in sys.argv[1:]:
            print arg

    if __name__ == "__main__":
        main()
```

The `__name__` variable is set to the name of the executing module, or `"__main__"` if this is the top-level module. The pattern shown, where we test `__name__` before executing any code, is a common one; it allows other Python scripts to safely import this one, improving reuse.

If you want to parse command-line arguments like flags etc, there is an `argparse` library as part of the standard distribution but a much easier way IMO is to use [docopt](http://docopt.org/): just write the help string and `docopt` generates the parse for you. Another option to look at is [click](http://click.pocoo.org/5/); it seems to be gaining popularity but I have not used it.

## An Overview of Python Types

See https://docs.python.org/3/library/stdtypes.html for detailed documentation.

The main types are:

| TYPE      | GROUP     | MUTABLE? |
|-----------|-----------|----------|
| int       | Numerics  | N        |
| float     | Numerics  | N        |
| complex   | Numerics  | N        |
| str       | Sequences | N        |
| bytes     | Sequences | N        |
| bytearray | Sequences | Y        |
| list      | Sequences | Y        |
| tuple     | Sequences | N        |
| range     | Sequences | N        |
| set       | Sets      | Y        |
| frozenset | Sets      | N        |
| dict      | Mapping   | Y        |

In addition, modules, classes, instances, methods, and functions are all types. The Boolean constants `True` and `False`, and the value `None`, are instances of their own special types, and there are several other special cases like this. See the link above for more. Note that there is a string type but not a character type; characters are not treated any differently from other strings.

### The Boolean Truth Value of Types

Any object can be tested for truth value, for use in an `if` or `while` condition or as operand in a Boolean expression.

By default, an object is considered true unless its class defines either a `__bool__()` method that returns False or a `__len__()` method that returns zero, when called with the object. Zero numeric values are considered False, as are empty collections or sequences, and vice-versa.

Operations and built-in functions that have a Boolean result always return `0` or `False` for false and `1` or `True` for true, unless otherwise stated.

Important exception: the Boolean operations `or` and `and` always return one of their operands. This allows for useful defaults using Boolean expressions with `or`:


```python
s = None

name = s or "N/A"

print(name)
```

    N/A


### None

Python has no null object, but has a special object instance `None`.

To test if an object is `None`, use `is` or `is not`, not `==` or `!=`.


```python
a = None
print(a is None)
print(a is not None)
```

    True
    False


`is` tests if the arguments refer to the same object, while `==` tests if they have the same value (in general; in reality it does whatever the `__eq__` dunder-method on the left-hand-side argument defines). Python keeps a pool of string literals and reuses them if it can, so in the example below `a` and `b` both refer to the same string literal while `c` does not:


```python
a = "3"
b = "3"
c = f"{3}"
print(a == b)
print(a is b)
print(a == c)
print(a is c)
```

    True
    True
    True
    False


### Numbers

Most of the typical operators you know from other languages are supported. Here are some more-specific to Python:


```python
print(bool(3))  # Convert to Boolean
print(str(3))  # Convert to string
print(bool(0))
```

    True
    3
    False



```python
print(3 // 2)  # Integer division with truncation
print(3 / 2)  # Float division
```

    1
    1.5



```python
print(int(2.5)) # Convert to int with truncation
print(round(2.5))  # Convert to int with rounding (oddly, round() with 0 
print(round(3.5))  #   decimal places rounds to even number, not up).
print(round(2.5001))  # Convert to int with rounding
```

    2
    2
    3



```python
# round can take an additional argument for a power of 10 specifying precision
print(round(9876.54321, 2))  # round to 2 decimal places
print(round(9876.54321, -2))  # round to nearest 100 (10^2)
```

    9876.54
    9900.0



```python
print(2 ** 3)  # Exponentiation
print(~3)  # Bitwise inverse
print(2**120)  # Python ints are arbitrary precision, not 64-bit
```

    8
    -4
    1329227995784915872903807060280344576



```python
print(2.0.is_integer())
print(2.5.as_integer_ratio())  # Convert to fraction tuple; we'll cover tuples later
```

    True
    (5, 2)


Note that `+=` and `-=` (and `*=`, etc) are supported but `++` and `--` are not. Use `+=1` and `-=1` instead.

Because even integer literals are objects with some overhead, Python has an optimization where it makes singleton instances of all small integers from -5 to 256. This can in rare situations trip you up. 


```python
a = 256
b = 257
c = -5
d = -6
print(a is 256)
print(b is 257)
print(c is -5)
print(d is -6)
```

    True
    False
    True
    False


### Strings

Python 3 strings are Unicode. String literals can use single our double quotes (but must use same type to close as to open). Multi-line strings are most easily written using triple quotes.


```python
print('foo')
print("bar")
print('"foo"')
print("'bar'")
print("""I am a 
multiline string""")
```

    foo
    bar
    "foo"
    'bar'
    I am a 
    multiline string


You can use the usual suspects of `\n`, `\t`, etc in strings, and use `\` to escape special characters like quotes and `\` itself.


```python
a = "the cat sat on the mat"
print(len(a))  # len gets the length of the string; implemented by __len__
```

    22



```python
print("cat" in a)  # 'in' is implemented by __contains__
print("dog" in a)
```

    True
    False



```python
print(a[0])  # Implemented by __getitem__
a[0] = "t"  # No can do; strings are immutable.
```

    t



    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-20-b63b8912561d> in <module>()
          1 print(a[0])  # Implemented by __getitem__
    ----> 2 a[0] = "t"  # No can do; strings are immutable.
    

    TypeError: 'str' object does not support item assignment



```python
# Some useful functions. Note these all return copies of the string; strings are immutable!
print(a.lower())
print(a.upper())
print(a.capitalize())  # Capitalize first letter
```

    the cat sat on the mat
    THE CAT SAT ON THE MAT
    The cat sat on the mat



```python
# Like any object that supports __len__ and __getitem__, strings are sliceable.
# Slicing uses [start:end] or [start:end:increment] where any of these are optional
# start defaults to 0, end to __len__(), and increment to 1. 
# start and end can be positive (from start of string) or negative (from end of string).

print(a[2:])   # skip first two characters
print(a[-7:])  # the last 7 characters
print(a[2:6])  # 4 characters starting after 2nd character
print(a[::2])  # Every second character
```

    e cat sat on the mat
    the mat
    e ca
    tectsto h a



```python
# Use find and rfind to find first/last occurence of a string; return offset or -1 if not found
# You can also use index/rindex which are similar but raise ValueError exception if not found.

print(a.find('he'))
print(a.rfind('he'))
print(a.find('cat'))
print(a.find('dog'))
```

    1
    16
    4
    -1



```python
# You can convert from character to ordinal or vice-versa with ord() and chr()
print(chr(65))
print(ord('A'))
```

    A
    65



```python
# Python has no character type, just string. So functions that would apply to just 
# a character in other languages apply to entire string in Python.
print("123".isdigit())
print("1X3".isdigit())
print("NOOOOooo".isupper())
```

    True
    False
    False


There are many more string operations available; these are just the basics. You can encode and decode strings using other encodings; see https://docs.python.org/3/howto/unicode.html for details.

### Lists

Lists are ordered, mutable sequences. They can be indexed, sliced (more on that below), appended to, have elements deleted, and sorted. They are heterogeneous. Examples:


```python
a = [1, 2, 3, "cat"]

print(a)
print(len(a))  # len() gives the length of the list
print(a[1])  # [] can be used to index in to the list; implemented by list.__getitem__; assignment uses list.__setitem__
print(a[-1])  # negative indices can be used to index from the end of the list (-1 for last element)
```

    [1, 2, 3, 'cat']
    4
    2
    cat



```python
# * can be used to create multiple concanenated copies of a list; implemented by list.__mul__
    
print(a)
a = a * 2 
print(a)
```

    [1, 2, 3, 'cat']
    [1, 2, 3, 'cat', 1, 2, 3, 'cat']



```python
# `in` can be used to check for membership; implemented by list.__contains__

print(a)
print('cat' in a)  
print('dog' in a)
```

    [1, 2, 3, 'cat', 1, 2, 3, 'cat']
    True
    False



```python
print(a)
print(['dog'] + a)  # + can be used to concanetenate lists; implemented by list.__add__
a.append('dog')  # append() can be used for concatenating elements
print(a)
```

    [1, 2, 3, 'cat', 1, 2, 3, 'cat']
    ['dog', 1, 2, 3, 'cat', 1, 2, 3, 'cat']
    [1, 2, 3, 'cat', 1, 2, 3, 'cat', 'dog']



```python
print(a)
print(a.index('dog')) # Get index of first matching entry; throws exception if not found
print(a.count('cat'))  # Count the number of instances of an element
```

    [1, 2, 3, 'cat', 1, 2, 3, 'cat', 'dog']
    8
    2



```python
print(a)
a.remove('dog')  # Remove first matching instance of element
print(a)
del a[-1]  # Remove element at index; implementedby list.__del__
```

    [1, 2, 3, 'cat', 1, 2, 3, 'cat', 'dog']
    [1, 2, 3, 'cat', 1, 2, 3, 'cat']



```python
# reverse() reverses the order of the list in place; implemented by list.__reversed__
print(a)
a.reverse()  
print(a)
```

    [1, 2, 3, 'cat', 1, 2, 3]
    [3, 2, 1, 'cat', 3, 2, 1]



```python
# for..in iterates over elements
    
print(a)
for elt in a: 
    print(elt)
```

    [3, 2, 1, 'cat', 3, 2, 1]
    3
    2
    1
    cat
    3
    2
    1



```python
# enumerate() will return tuples of index, value
print(a)
for i, v in enumerate(a):
    print(f'Value at index {i} is {v}')  # f'' is a format string that can contain code in {}
```

    [3, 2, 1, 'cat', 3, 2, 1]
    Value at index 0 is 3
    Value at index 1 is 2
    Value at index 2 is 1
    Value at index 3 is cat
    Value at index 4 is 3
    Value at index 5 is 2
    Value at index 6 is 1



```python
b = list(a)  # Makes a shallow copy; can also use b = a.copy()
print(b)
print(a == b)  # Elementwise comparison; implemented by list.__eq__
b[-1] += 1  # Add 1 to last element
print(a == b)
print(a > b)  # Compares starting from first element; implemented by list.__gt__
print(a < b)  # Compares starting from first element; implemented by list.__lt__
```

    [3, 2, 1, 'cat', 3, 2, 1]
    True
    False
    False
    True



```python
print(a)
a.pop()  # Removes last element
print(a)
a.pop(0)  # removes element at index 0
print(a)
```

    [3, 2, 1, 'cat', 3, 2, 1]
    [3, 2, 1, 'cat', 3, 2]
    [2, 1, 'cat', 3, 2]



```python
# You can join a list of words into a string
','.join(['cat', 'dog'])
```




    'cat,dog'




```python
# Like any object that supports __len__ and __getitem__, lists are sliceable.
# Slicing uses [start:end] or [start:end:increment] where any of these are optional
# start defaults to 0, end to __len__(), and increment to 1. 
# start and end can be positive (from start of string) or negative (from end of string).
x = [1, 2, 3, 4, 5, 6]
print(x[2:])
print(x[1:3])
print(x[-3:])
print(x[::2])
```

    [3, 4, 5, 6]
    [2, 3]
    [4, 5, 6]
    [1, 3, 5]



```python
# Use insert() to insert at some position. This is done in-place.
x.insert(2, 'A')
print(x)
x.insert(3, [1, 2])  # Note: insert() is for elements, so [1, 2] is a single element, not expanded
print(x)
```

    [1, 2, 'A', 3, 4, 5, 6]
    [1, 2, 'A', [1, 2], 3, 4, 5, 6]



```python
a.clear()  # empty the list
print(a)
```

    []


### Dicts

Dictionaries are mutable mappings of keys to values. Keys must be hashable, but values can be any object. 

---
_Under the hood_

A hashable object is one that defines a `__hash__` dunder-method, and an `__eq__` dunder method; if two objects are equal their hashes must be the same or the results may be unpredictable. 

---



```python
# dict literals (actually a list of dicts in this example)

contacts = [
    {
        'name': 'Alice',
        'phone': '555-123-4567'
    },
    {
        'name': 'Bob',
        'phone': '555-987-6543'        
    }
]
contacts
```




    [{'name': 'Alice', 'phone': '555-123-4567'},
     {'name': 'Bob', 'phone': '555-987-6543'}]




```python
# Use [key] to get an item; this calls dict.__getitem__
contacts[0]['name']
```




    'Alice'




```python
# Use dict[key] = value to change an item; this calls dict.__setitem__
contacts[0]['name'] = 'Carol'
contacts[0]
```




    {'name': 'Carol', 'phone': '555-123-4567'}




```python
# Trying to use a non-existent key raises an exception
contacts[0]['address']
```


    ---------------------------------------------------------------------------

    KeyError                                  Traceback (most recent call last)

    <ipython-input-44-0a84b14a0ce5> in <module>()
          1 # Trying to use a non-existent key raises an exception
    ----> 2 contacts[0]['address']
    

    KeyError: 'address'



```python
# You can avoid above and return a default value by using .get()
print(contacts[0].get('name', 'No name'))
print(contacts[0].get('address', 'No address'))
```

    Carol
    No address



```python
# Use 'in' to see if a key exists in a dict; this calls dict.__contains__
print('name' in contacts[0])
print('address' in contacts[0])
```

    True
    False



```python
# Test for equality with '==' and !=; this calls dict.__eq__ and dict.__ne__
print(contacts[0] == contacts[1])
print(contacts[0] == { 'name': 'Carol', 'phone': '555-123-4567'})
```

    False
    True



```python
# Use for-in to iterate over items; this calls dict.__iter__

for x in contacts[0]:
    print(x)
```

    name
    phone



```python
# Use len() to get number of items; this calls dict.__len__

print(len(contacts[0]))
```

    2



```python
# Use 'del' to delete a key from a dict; this calls dict.__delitem__
```


```python
# Use .clear() to empty dict (without changing references)

a = {'name': 'me'}
b = a
a.clear()
b
```




    {}




```python
# Contrast above with assigning empty dict
a = {'name': 'me'}
b = a
a = {}
b
```




    {'name': 'me'}




```python
# Use .keys(), .values() or .items() to get the keys, values, or both
```

There are some alternative implementations in the `collections` module; you won't need these now but they may come in handy in the future, especially the first two:

* `collections.OrderedDict`s remember the order of insertion so this is preserved when iterating over the entries or keys
* `collections.defaultdict`s can specify a type in the constructor whose return value will be used if an entry can't be found
* `collections.ChainMap`s group multiple dictionaries into a single item for lookups; inserts go in the first dictionary

### Sets

A set is a mutable unordered collection that cannot contain duplicates. Sets are used to remove duplicates and test for membership. One use for sets is to quickly see differences. For example, if you have two dicts and want to see what keys are in one but not the other:


```python
a = {'food': 'ham', 'drink': 'soda', 'desert': 'ice cream'}
b = {'food': 'tofu', 'desert': 'cake'}

set(a) - set(b)
```




    {'drink'}



Sets are less commonly used than lists and dicts and we will not discuss them further here. You can read more here: https://docs.python.org/3/library/stdtypes.html#set-types-set-frozenset

### Tuples

Tuples are immutable sequences. Typically they are used to store record type data, or to return multiple values from a function. Tuples behave a lot like lists and support many of the same operations with similar behavior, aside from their immutability. We'll consider them briefly here.

The `collections` package defines a variant `namedtuple` which allows each field to be given a name; we won't go into that here other than to point out its existence. `collections` also defines a `deque` class; stacks are easy to implement just with the built-in list type.


```python
('dog', 'canine')  # tuple
```




    ('dog', 'canine')




```python
('dog')  # Not a tuple! This is just a string in parens
```




    'dog'




```python
('dog',)  # For a single-valued tuple, use a trailing comma to avoid above issue
```




    ('dog',)




```python
'dog',  # Parentheses are often optional
```




    ('dog',)




```python
# Indexing can be used to get at elements, much like lists
print(('dog', 'canine')[0])
print(('dog', 'canine')[1])
print(('dog', 'canine')[-2])
print(('dog',)[0])
print(('dog',)[1])
```

    dog
    canine
    dog
    dog



    ---------------------------------------------------------------------------

    IndexError                                Traceback (most recent call last)

    <ipython-input-59-c2e4b522d95a> in <module>()
          4 print(('dog', 'canine')[-2])
          5 print(('dog',)[0])
    ----> 6 print(('dog',)[1])
    

    IndexError: tuple index out of range



```python
# We can unpack a tuple through assignment to multiple variables
a = ('dog', 'bone')
animal, toy = a
print(animal)
print(toy)
```

    dog
    bone



```python
# But need to ensure we use the right number of variables
a = ('dog', 'bone')
animal, toy, place = a
```


    ---------------------------------------------------------------------------

    ValueError                                Traceback (most recent call last)

    <ipython-input-61-fee6f9af1778> in <module>()
          1 # But need to ensure we use the right number of variables
          2 a = ('dog', 'bone')
    ----> 3 animal, toy, place = a
    

    ValueError: not enough values to unpack (expected 3, got 2)



```python
a = ('dog', 'bone', 'house')
animal, toy = a
```


    ---------------------------------------------------------------------------

    ValueError                                Traceback (most recent call last)

    <ipython-input-62-fff6c985f996> in <module>()
          1 a = ('dog', 'bone', 'house')
    ----> 2 animal, toy = a
    

    ValueError: too many values to unpack (expected 2)



```python
# Tuples allow us to do a neat trick in Python that is harder in many languages - swap two values without using a
# temporary intermediate.
# Note what is going on here: the RHS of the assignment is creating a tuple; the LHS is unpacking the tuple.

a = 1
b = 2
print(a,b)
a, b = b, a
print(a,b)
```

    1 2
    2 1


### Exercise

Earlier we defined a function `add` that takes two parameters and applies the + operator to them, which in turn calls the `__add__` dunder-method on the first argument, passing the second argument as a parameter.

Try some experiments with calling add on different types and mixtures of arguments so you get some idea of what types have and `__add__` dunder method and what types of arguments each can sensibly handle.

## Some built-in Functions

See https://docs.python.org/3.6/library/functions.html for a full list and more details.

`abs(num)` - Return absolute value


```python
print(abs(3))
print(abs(-3))
```

    3
    3


`all(iterable)` - returns True if all items in the iterable are True


```python
print(all([True, True, True]))
print(all([True, False, True]))
```

    True
    False


`any(iterable)` - returns True is any item in the iterable is True.


```python
print(any([False, False]))
print(any([False, True]))
```

    False
    True


`filter(fn, iter)` - construct an iterator from the elements of iterable object `iter` for which a function `fn` returns true.


```python
names = ["John Smith", "Alan Alda"]

# Get the names that start and end with same letter
for i in filter(lambda s: s[0].upper() == s[-1].upper(), names):
    print(i)
```

    Alan Alda


`input` - get input from the console


```python
n = input("What is your name?")
print(f'Hello {n}!')
```

    What is your name?Graham
    Hello Graham!


`isinstance` - check if an object has a certain type


```python
s = 'abc'
n = 123
print(isinstance(s, int))
print(isinstance(s, str))
print(isinstance(n, int))
print(isinstance(n, str))
```

    False
    True
    True
    False


`iter` - create an sequential iterable from an object; we will discuss iterables later


```python
x = iter([1, 2, 3, 4])
print(x)
print("Before first next()")
print(next(x))  # returns first item and advances
print("Before second next()")
print(next(x))  # returns second item and advances
print("After second next()")
for v in x:  # iterates through remaining items
    print(v)
```

    <list_iterator object at 0x10ff53978>
    Before first next()
    1
    Before second next()
    2
    After second next()
    3
    4


`len` - calls the object's `__len__` method to get the length.

`map` - similar to `filter` but returns an iterable with the results of applying the function


```python
names = ["John Smith", "Alan Alda"]

# Get a list of bools, one for each name, specifying if the name starts and ends with the same letter.
print(list(map(lambda s: s[0].upper() == s[-1].upper(), names)))
```

    [False, True]


`max(arg1,...)` - returns the largest arg. If a single iterable arg is given it will iterate.

`min(arg1, ...)` - returns the smallest arg


```python
print(max(2, 3, 1))  # Multiple scalar args
print(max([3, 2, 1])) # Single list arg
print(max([3, 2, 1], 4))  # Not allowed
```

    3
    3



    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-72-5ebfda590ac7> in <module>()
          1 print(max(2, 3, 1))  # Multiple scalar args
          2 print(max([3, 2, 1])) # Single list arg
    ----> 3 print(max([3, 2, 1], 4))  # Not allowed
    

    TypeError: '>' not supported between instances of 'int' and 'list'


`next` - gets next item from an iterable; see the section on iterables and example for `iter` above.

`repr` - calls the object `__repr__` method to get a string representation. This is the *formal* representation while `__str__` returns the *informal* representation. Another way of thinking about this is that `__str__` returns the value of the object when used as a string, while `__repr__` returns a printable representation of the object's state. In Jupyter, when displaying an object, `__repr__` will be used if possible, with `__str__` used as a fallback. 

`reversed` - makes a copy of the object with items in reversed order (object must support `__len__` and `__getitem__`)

`round` - rounds number to some number of decimal places (default 0)


```python
pi = 3.1415927
print(round(pi))
print(round(pi, 3))
```

    3
    3.142


`sorted(list)` - returns a sorted version of the list.


```python
print(sorted([3, 1, 3]))
```

    [1, 3, 3]


`sum(iterable)` - returns the sum of the iterable


```python
print(sum([1, 2, 3]))
```

    6


`type(obj)` - return the type of an object


```python
print(type('foo'))
```

    <class 'str'>


`zip(list, ...)` - combines multiple lists into a single list of tuples. Note this returns a lazy iterable, not a list


```python
print(zip(['a', 'b', 'c'], [1, 2, 3]))
print(list(zip(['a', 'b', 'c'], [1, 2, 3])))  # instantiates the iterable as a list
```

    <zip object at 0x10fcdc408>
    [('a', 1), ('b', 2), ('c', 3)]


## String Formatting

String formatting has evolved over time with Python. Python 3.6 introduced "format strings" which allow code to be directly embedded in the string. This is an improvement over older approaches and we will use it extensively.
Format strings have an `f` prefix and include code in `{}`. For example:


```python
a = 10
print(f"2 x {a} = {2*a}")
```

    2 x 10 = 20


If you need to use the old approaches, there are a lot of details here: https://pyformat.info/ (this doesn't seem to cover format strings yet though). That site covers things like padding, justification, truncation, leading zeroes, fixing number of decimal places, etc. We won't cover these here except the latter:


```python
a = 1.23456
print(a)
print(f'{a:.2f}')  # Float restricted to two decimal places
print(f'{a:06.2f}')  # Float restricted to two decimal places and padded with leading zeroes if less than 6 chars
```

    1.23456
    1.23
    001.23


When you use `f'{a}'`, Python will look in turn for a `__format__`, a `__repr__` or a `__str__` method to call to get the string representation of `a`. You can force it to use `__repr__` with `f'{a!r}'` or to use `__str__` with `f'{a!s}'`.

### Exercise

Define a function that takes an argument, and sees if the results of calling `__repr__` vs `__str__` are the same; if not, the function should print a message showing the difference. Experiment with calling this function with a few different types of arguments.


```python

```

## Sorting

We've already seen the `sorted` function, that can create a sorted list from any iterable:


```python
d = [3,5,2,4,1,7]
for i in sorted(d):
    print(i)
```

    1
    2
    3
    4
    5
    7


You can do a descending sort by adding a `reverse=True` argument:


```python
for i in sorted(d, reverse=True):
    print(i)
```

    7
    5
    4
    3
    2
    1


You can sort a list in place with `sort`, but this only applies to lists:


```python
print(d)
d.sort()
print(d)
```

    [3, 5, 2, 4, 1, 7]
    [1, 2, 3, 4, 5, 7]


You can read more about sorting here, including how to sort composite objects like dictionaries, tuples and nested lists, and by multiple keys: https://docs.python.org/3/howto/sorting.html

### Exercise

Define a function that takes a single argument, and returns `True` if the argument is already sorted. Stretch: if not sorted, print out the first mismatch. Note: if you are struggling skip this exercise for now and return to it later after we have covered things like Python statements and exceptions.


```python

```

## Statements

Here we will consider statements. We'll leave some statements to when we get to exceptions, functions and classes.

For more info on statements see https://docs.python.org/3/reference/simple_stmts.html

### pass

The `pass` statement is a no-op. This is needed in Python as the language doesn't use braces, so it is the equivalent of `{}` in Java- or C-like languages.

### del

`del` is used to delete an object; it isn't used much but can be useful if the object uses a lot of memory to allow it to be garbage-collected.

### for, break and continue

You can loop over any iterable with `for...in`. `break` and `continue` are supported, and behave in the expected fashion.


```python
for i in ['green eggs', 'ham']:
    print(i)
```

    green eggs
    ham



```python
for i in 'green eggs':
    print(i)
```

    g
    r
    e
    e
    n
     
    e
    g
    g
    s



```python
for i in {'a': 1, 'b': 2}: # This will loop over keys
    print(i)
```

    a
    b



```python
for i in {'a': 1, 'b': 2}.values(): # This will loop over values
    print(i)
```

    1
    2



```python
for i in {'a': 1, 'b': 2}.items():  # This will loop over key-value pairs as tuples
    print(i)
```

    ('a', 1)
    ('b', 2)



```python
for i in [1, 2, 3]:
    print(i)
```

    1
    2
    3



```python
for i in enumerate([1, 2, 3]):  # Returns (index, value) tuples
    print(i)
```

    (0, 1)
    (1, 2)
    (2, 3)



```python
for index, value in enumerate([1, 2, 3]):  # We can unpack the (index, value) tuples
    print(f'At position {index} we have value {value}')
```

    At position 0 we have value 1
    At position 1 we have value 2
    At position 2 we have value 3



```python
for i in range(1, 10):
    print(i)
```

    1
    2
    3
    4
    5
    6
    7
    8
    9



```python
for i in range(1, 10, 2):
    print(i)
```

    1
    3
    5
    7
    9


Python has an unusual construct: for..else. The else part is executed if there was no early break from the loop.

This is a common construct in other languages:

```python
    # See if the list has an even number and then take an action.
    has_even_number = False
    for elt in [1, 2, 3]:
        if elt % 2 == 0:
            has_even_number = True
            break
    if not has_even_number:
        print "list has no even numbers"
```

but in Python, we can just do:

```python
    for elt in [1, 2, 3]:
        if elt % 2 == 0:
            break
    else:
        print "list has no even numbers"
```

I.e. the `else` statement will be executed if the loop completes normally (does not exit through a `break`).

### while

`while` loops are very straighforward:


```python
i = 0
while i < 10:
    print(i)
    i += 2
```

    0
    2
    4
    6
    8


`while...else` is supported:


```python
i = 0
while i < 10:
    print(i)
    i += 2
else:
    print('Done')
```

    0
    2
    4
    6
    8
    Done



```python
i = 0
while i < 10:
    print(i)
    if i % 2 == 0:
        print('Found an even number!')
        break
    i += 2
else:
    print('No even numbers!')
```

    0
    Found an even number!



```python
i = 1
while i < 10:
    print(i)
    if i % 2 == 0:
        print('Found an even number!')
        break
    i += 2
else:
    print('No even numbers!')
```

    1
    3
    5
    7
    9
    No even numbers!


### if Statement and Boolean Expressions

Python uses `if...elif...else` syntax:


```python
grade = 75
if grade > 90:
    print('A')
elif grade > 80:
    print('B')
elif grade > 70:
    print('C')
else:
    print('D')
```

    C


`and`, `or` and `not` are Boolean operators, while `&`, `|` and `^` are bitwise-operators. Short-circuiting rules apply:


```python
1 and 1/0
```


    ---------------------------------------------------------------------------

    ZeroDivisionError                         Traceback (most recent call last)

    <ipython-input-98-d26a3ac7f29d> in <module>()
    ----> 1 1 and 1/0
    

    ZeroDivisionError: division by zero



```python
1 or 1/0
```




    1




```python
0 and 1/0
```




    0




```python
0 or 1/0
```


    ---------------------------------------------------------------------------

    ZeroDivisionError                         Traceback (most recent call last)

    <ipython-input-101-a829942d3284> in <module>()
    ----> 1 0 or 1/0
    

    ZeroDivisionError: division by zero


You can combine multiple range comparisons into a single one:


```python
print(0 < 2 < 4)
print(2 < 0 < 4)
```

    True
    False


Note that the Boolean literals are `True` and `False`, with capitalized first letters.


```python
print(0 < 2 < 4 < 6)
```

    True


If an instance of a class is used in a Boolean expression, it is evaluated by calling its `__bool__` method if it has one, else its `__len__` method (where non-zero is `True`), else it is considered `True`.

Python doesn't support conditional expressions like `:?` but does support ternary expressions with `if...else`:


```python
for count in range(0, 3):
    print(f'{count} {"Widget" if count == 1 else "Widgets"}')
```

    0 Widgets
    1 Widget
    2 Widgets


### with

`with` is used for scoped use of classes that need to clean up when they are no longer used (e.g. file objects that need to release underlying file handles). 

The most common place you'll see this is with file reading and writing, which we cover in the next section.

---
> _Under the Hood_
>
> When the “with” statement is executed, Python evaluates the following expression, calls the `__enter__` method on the resulting value (a “context guard”), and assigns whatever `__enter__` returns to the variable given by as. Python will then execute the code body, and no matter what happens in that code, call the guard object’s `__exit__` method.
> 
> As an extra bonus, the `__exit__` method can look at the exception, if any, and suppress it or act on it as necessary (to suppress it, it just needs to return `True`).
> 
> We're getting ahead of ourselves here with classes, but here is an example:


```python
class Wither:
    def __enter__(self):
        return 'green eggs'
    def __exit__(self,  type, value, traceback):
        print('ham')
    
with Wither() as x:
    print(x)
```

    green eggs
    ham


## Reading and Writing Files

Python has a built-in `open` function for opening files for reading and writing: https://docs.python.org/3.6/library/functions.html#open

The simplest for of reading a file is just:

```python
with open('myfile.txt') as f:
    for line in f:
        print(line)
```

and writing a file, assuming we have a list of strings `data`:

```python
with open('myfile.txt', 'w') as f:
    for line in data:
        f.write(line)
```

You can see more detailed examples in the tutorial, section 7.2, here: https://docs.python.org/3/tutorial/inputoutput.html

If you are doing more sophisticated operations with files you may want to look at the `pyfilesystem` package: https://www.pyfilesystem.org/. This provides a richer set of functionality over a variety of different "virtual" file systems, like zipfiles, tarfiles, FTP, SMB, DLNA and WebDAV servers, and services like DropBox.

## Functions and Lambdas

Recall that Python named functions are defined with `def`:


```python
def add(a, b):
    return a + b

add(2, 3)
```




    5



Default arguments are allowed. If a default argument is specified, then all following arguments must have defaults as well:


```python
def add(a, b=1):
    print(f'a={a}, b={b}')
    return a + b

print(add(2, 3))
print(add(2))
print(add())
```

    a=2, b=3
    5
    a=2, b=1
    3



    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-107-ad63163207a7> in <module>()
          5 print(add(2, 3))
          6 print(add(2))
    ----> 7 print(add())
    

    TypeError: add() missing 1 required positional argument: 'a'


Arguments with no defaults are *positional arguments* and must be specified in order _except_ if they are named explicitly when calling the function:


```python
print(add(b=2, a=1))
```

    a=1, b=2
    3


When arguments are named as in the above example they are called *keyword arguments*.

You can use `*args` for a variable number of non-keyword arguments, which will be available internally as a list:


```python
def multiply(*args):
    z = 1
    for num in args:
        z *= num
    return z
    
print(multiply(1, 2, 3, 4))
```

    24



```python
def foo(*args):
    for i in range(0, len(args)):
        print(f'Argument {i} is {args[i]}')

        
foo(1, 2, 'cat')
```

    Argument 0 is 1
    Argument 1 is 2
    Argument 2 is cat


When capturing positional arguments like this, all following arguments *must* be keyword arguments:


```python
def foo(*args, a, b):
    l = list(args)
    l.extend([a, b])
    print(l)
    
foo(1, 2, a=3, b=4)
foo(1, 2, 3, b=4)
```

    [1, 2, 3, 4]



    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-8-e7dbf56a0506> in <module>()
          5 
          6 foo(1, 2, a=3, b=4)
    ----> 7 foo(1, 2, 3, b=4)
    

    TypeError: foo() missing 1 required keyword-only argument: 'a'


In Python 3, you can require keyword-only arguments without having to capture positional arguments by using `*` on its own:


```python
def foo(pos1, pos2, *, key1, key2):
    print([pos1, pos2, key1, key2])
    
foo(1, 2, key1=3, key2=4)
foo(1, 2, 3, key2=4)
```

    [1, 2, 3, 4]



    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-11-3fa2d715c035> in <module>()
          3 
          4 foo(1, 2, key1=3, key2=4)
    ----> 5 foo(1, 2, 3, key2=4)
    

    TypeError: foo() takes 2 positional arguments but 3 positional arguments (and 1 keyword-only argument) were given


Of course, you don't have to have any positional arguments above if you want just keyword arguments.

For capturing multiple keyword arguments, you can use `**kwargs`, which will be available internally as a dictionary:


```python
def foo(*args, **kwargs):
    for i in range(0, len(args)):
        print(f'Positional argument {i} is {args[i]}')
    for k, v in kwargs.items():
        print(f'Keyword argument {k} is {v}')
        
foo('cat', 1, clothing='hat', location='mat')
```

    Positional argument 0 is cat
    Positional argument 1 is 1
    Keyword argument clothing is hat
    Keyword argument location is mat


You can mix all types of arguments but the order is important:
* Formal positional arguments
* `*args`
* Keyword arguments
* `**kwargs`

You can do the opposite as well - pass a list instead of several positional arguments, and a dictionary instead of several keyword arguments, by using `*` and `**`:


```python
def foo(pos1, pos2, named1='a', named2='b'):
    print(f"Positional 1 is {pos1}")
    print(f"Positional 2 is {pos2}")
    print(f"Named1 is {named1}")
    print(f"Named1 is {named2}")    
    
p = [1, 2]
n = {'named1': 'cat', 'named2': 'hat'}
foo(*p, **n)
```

    Positional 1 is 1
    Positional 2 is 2
    Named1 is cat
    Named1 is hat


The above is actually a common pattern in Python when writing wrapper functions that need to support arbitrary arguments that they are just going to pass on to some other function. For example, say we wanted to write a wrapper that timed the execution of a function:


```python
import datetime as dt


def foo(a, b=None, c=None):
    print(f'a={a}, b={b}, c={c}')


def log_time(fn, *args, **kwargs):
    start = dt.datetime.now()
    fn(*args, **kwargs)
    end = dt.datetime.now()
    print(f"{fn} took {(end-start).microseconds} microseconds")
    
log_time(foo, 1, c='hello')
    
```

    a=1, b=None, c=hello
    <function foo at 0x10ff6dae8> took 58 microseconds


Variables referenced in a function are either local or arguments. To access a global variable you must explicitly declare it global (but it is better to avoid using globals):


```python
x = 2

def foo():
    x = 1  # This is local
    
print(x)  # This is the global
foo()
print(x)
```

    2
    2



```python
x = 2

def foo():
    global x
    x = 1
    
print(x)
foo()
print(x)
```

    2
    1


Functions can be nested. In Python 3 you can declare a variable as "nonlocal" to access an outer but non-global scope.


```python
def outside():
    msg = "Outside!"
    def inside():
        msg = "Inside!"  # This is different to the one in outside()
        print(msg)
    inside()
    print(msg)
    
outside()
```

    Inside!
    Outside!



```python
def outside():
    msg = "Outside!"
    def inside():
        nonlocal msg  # This is the same as the one in outside()
        msg = "Inside!"
        print(msg)
    inside()
    print(msg)
    
outside()
```

    Inside!
    Inside!


It is good practice to follow the `def` line with a _docstring_ to document the function. There are different conventions for how this should be formatted; I like the Google style: http://sphinxcontrib-napoleon.readthedocs.io/en/latest/example_google.html


```python
def add(a, b):
    """Adds two objects and returns the result.

    Args:
        a: The first parameter.
        b: The second parameter.

    Returns:
        The result of adding a and b.
    """
    return a + b

# Now we can use help() to get the docstring.
help(add)
```

    Help on function add in module __main__:
    
    add(a, b)
        Adds two objects and returns the result.
        
        Args:
            a: The first parameter.
            b: The second parameter.
        
        Returns:
            The result of adding a and b.
    


You can return multiple values from a function (really just a tuple):


```python
def sum_diff(a, b):
    return a+b, a-b

print(sum_diff(3, 2))
x, y = sum_diff(4, 5)
print(x)
print(y)
```

    (5, 1)
    9
    -1


Python supports continuations with yield (this returns a generator which we will discuss later):


```python
def get_next_even_number(l):
    for v in l:
        if v % 2 == 0:
            yield v
    
x = [1, 2, 3, 4, 5, 6]
for e in get_next_even_number(x):
    print(e)
```

    2
    4
    6


Note that `def` statements are executed at their level of indentation, and they create function objects that can be called later, including evaluating the default argument values. This means you should be careful when specifying default values for arguments; stick to scalar variables. In particular avoid using things like empty lists! Look at how this can go wrong:


```python
def beware(a=[]):
    print(a)
    a.append('gotcha!')
    
beware()
beware() # No longer empty list!
```

    []
    ['gotcha!']


What happened above is that the empty list argument was created at function definition time, and at function call time a is assigned a default value which is a reference to the previously created list object. If the list changes those changes will persist.

Instead, use something like:


```python
def beware(a=None):
    if a is None:
        a=[]
    print(a)
    a.append('gotcha!')
    
beware()
beware() # Now we are safe
```

    []
    []


Finally, you can use `lambda` to define anonymous functions. These will be very useful when we get to using Pandas for data manipulation:


```python
adder = lambda a, b: a + b

adder(1, 2)
```




    3



## Comprehensions

Comprehensions are a powerful feature in Python, allowing lists, dictionaries and tuples to be constructed from iterative computations with minimal code. These are best illustrated by examples:


```python
# A list of all squares from 1 to 25
[x*x for x in range(1, 6)]
```




    [1, 4, 9, 16, 25]




```python
# A list of all squares from 1 to 1024 except those divisble by 5
[x*x for x in range(1, 33) if (x*x) % 5 != 0]
```




    [1,
     4,
     9,
     16,
     36,
     49,
     64,
     81,
     121,
     144,
     169,
     196,
     256,
     289,
     324,
     361,
     441,
     484,
     529,
     576,
     676,
     729,
     784,
     841,
     961,
     1024]




```python
# Comprehensions can be nested
t = [
    ['1', '2'],
    ['3', '4']
]

# Make a list of lists from t where we convert the strings to floats
[[float(y) for y in x] for x in t]
```




    [[1.0, 2.0], [3.0, 4.0]]




```python
# Dictionary comprehension
{ f'Square of {x}': x*x for x in range(1, 6)}
```




    {'Square of 1': 1,
     'Square of 2': 4,
     'Square of 3': 9,
     'Square of 4': 16,
     'Square of 5': 25}



## Classes

We'll now turn to defining your own Python classes. If you are in a hurry to move to the next post in this series, you can skip this now and come back to it later.


```python
class Widget:  # same as "class Widget(object):"
    """ This is a Widget class. """  # Classes have docstrings too.
    
    def print_my_class(self):  # Instance method as it has a 'self' parameter
        """ Print the instance class. """
        print(self.__class__)  # __class__ is the easy way to get at an object's class
    
    @staticmethod
    def print_class():  # Static method as it has no 'self' parameter
        """ Print the class class. """
        print(Widget)
        
        
x = Widget()  # We don't use 'new' in Python
x.__doc__  # __doc__ has the docstring
```




    ' This is a Widget class. '



In Python, we can declare a class with `class(base)`. If the base class is omitted then `object` is assumed.

As mentioned earlier, instance methods take an explicit `self` first parameter which references the instance. So if `widget` is an instance of a `Widget` class and we call:

```python
widget.foo()
```

internally that gets converted to the equivalent of:

```python
Widget.foo(widget)
```

To declare an instance method, we omit the `self` argument and use a `staticmethod` decorator. The latter prevents the instance being passed as a parameter when we call the method from that instance.


```python
help(x)
```

    Help on Widget in module __main__ object:
    
    class Widget(builtins.object)
     |  This is a Widget class.
     |  
     |  Methods defined here:
     |  
     |  print_my_class(self)
     |      Print the instance class.
     |  
     |  ----------------------------------------------------------------------
     |  Static methods defined here:
     |  
     |  print_class()
     |      Print the class class.
     |  
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |  
     |  __dict__
     |      dictionary for instance variables (if defined)
     |  
     |  __weakref__
     |      list of weak references to the object (if defined)
    



```python
x.print_my_class()
```

    <class '__main__.Widget'>



```python
x.print_class()
```

    <class '__main__.Widget'>



```python
Widget.print_class()
```

    <class '__main__.Widget'>



```python
Widget.print_my_class()
```


    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-129-70eb78ad9fde> in <module>()
    ----> 1 Widget.print_my_class()
    

    TypeError: print_my_class() missing 1 required positional argument: 'self'


Note that if we had:

```python
class Foo():
     def s1():
         print('s1')

     @staticmethod
     def s2():
         print('s2')
```

then we could call `Foo.s1()` or `Foo.s2()` with no issues, but if `foo` was an instance of `Foo`, while we could call `foo.s2()` without a problem, if we called `foo.s1()` we would get an error:

```
TypeError: s1() takes 0 positional arguments but 1 was given
```

because Python would try to pass the instance as a parameter as it is missing @staticdecorator.

We can get the docstring of the class and more with `help`:


```python
help(Widget)
```

    Help on class Widget in module __main__:
    
    class Widget(builtins.object)
     |  This is a Widget class.
     |  
     |  Methods defined here:
     |  
     |  print_my_class(self)
     |      Print the instance class.
     |  
     |  ----------------------------------------------------------------------
     |  Static methods defined here:
     |  
     |  print_class()
     |      Print the class class.
     |  
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |  
     |  __dict__
     |      dictionary for instance variables (if defined)
     |  
     |  __weakref__
     |      list of weak references to the object (if defined)
    


### Constructors and visibility

A class does not require a constructor, but can have (at most) one. The constructor is an instance method named `__init__`. It can take additional parameters other than `self`.

Python does not support private or protected members. By convention, private members should be named starting with an underscore, but this is an 'honor system'; everything is public. Also by convention, you should avoid double underscores; that should be reserved for dunder-methods.


```python
class Bug:
    """ A class for creepy crawly things. """
    
    heads = 1  # This is a class variable
    
    def __init__(self, legs=6, name='bug'):
        self.legs = legs  # Any variable assigned to with self.var = ... in constructor is an instance variable
        self.name = name
    
    @staticmethod
    def _article(name):  # 'private' class method
        """ Return the English article for the given name. """
        return 'an'if 'aeiouAEIOU'.find(name[0]) >= 0 else 'a'

    def article(self):  # 'public' instance method
        """ Return the English article for the given name. """
        return Bug._article(self.name)
    
    def __repr__(self):  # __repr__ is called to get a printable representation of an object
        return f"I'm {Bug._article(self.name)} {self.name} with {self.legs} legs"

# Notice how help() will show help for article() but not _article().
# It respects the '_' convention for 'privacy'.
help(Bug)
```

    Help on class Bug in module __main__:
    
    class Bug(builtins.object)
     |  A class for creepy crawly things.
     |  
     |  Methods defined here:
     |  
     |  __init__(self, legs=6, name='bug')
     |      Initialize self.  See help(type(self)) for accurate signature.
     |  
     |  __repr__(self)
     |      Return repr(self).
     |  
     |  article(self)
     |      Return the English article for the given name.
     |  
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |  
     |  __dict__
     |      dictionary for instance variables (if defined)
     |  
     |  __weakref__
     |      list of weak references to the object (if defined)
     |  
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |  
     |  heads = 1
    



```python
Bug()
```




    I'm a bug with 6 legs




```python
Bug(legs=8)
```




    I'm a bug with 8 legs



It is recommended to always define a `__repr__` method on your classes.

### Inheritance

Python supports both single and multiple inheritance (which we won't discuss). To up-call to a base method with single-inheritance we use `super()`:


```python
class Insect(Bug):
    
    def __init__(self):
        super().__init__(name='insect')
        
Insect()
```




    I'm an insect with 6 legs




```python
class Spider(Bug):
    
    def __init__(self):
        super().__init__(legs=8, name='spider')
        
Spider()
```




    I'm a spider with 8 legs



### Under the Hood

You can skip this section if you're not interested, but it can be useful to have some understanding of how classes work in Python.

Classes and class instances both have a `.__dict__` attribute that holds their methods and variables/attributes. For example:


```python
class Example:
    """ this is a class docopt string. """
    
    class_var = 'this is a class variable'
    
    def __init__(self):
        """ This is an instance docopt string. """
        self.instance_var = 'this is an instance var'
        
    def class_method():
        """ This is a class method docopt string. """
        pass
    
    def instance_method(self):
        return self.instance_var
    
Example.__dict__
```




    mappingproxy({'__dict__': <attribute '__dict__' of 'Example' objects>,
                  '__doc__': ' this is a class docopt string. ',
                  '__init__': <function __main__.Example.__init__>,
                  '__module__': '__main__',
                  '__weakref__': <attribute '__weakref__' of 'Example' objects>,
                  'class_method': <function __main__.Example.class_method>,
                  'class_var': 'this is a class variable',
                  'instance_method': <function __main__.Example.instance_method>})



In the case of classes we really have a special object, a `mappingproxy`; this is a wrapper around a dictionary that makes it read-only and enforces that all keys are strings.


```python
# Similarly for an instance, although this really is a dict, not a mappingproxy.
e = Example()
print(e.__dict__)
print(e.__dict__.__class__)
```

    {'instance_var': 'this is an instance var'}
    <class 'dict'>



```python
# Instances have a .__class__ attribute that points to their class.
e.__class__
```




    __main__.Example




```python
# To change a class variable, qualify with the class name:

e2 = Example()
print(e.class_var)
print(e2.class_var)

Example.class_var = 'Changed class var'

# Note how it is changed for all instances
print(e.class_var)
print(e2.class_var)
```

    this is a class variable
    this is a class variable
    Changed class var
    Changed class var



```python
# If you qualify with an instance instead, you'll end up creating an instance variable instead!
e2.class_var = 'e2 class var is actually an instance var'
print(e.class_var)
print(e2.class_var)
print(e.__dict__)
print(e2.__dict__)
```

    Changed class var
    e2 class var is actually an instance var
    {'instance_var': 'this is an instance var'}
    {'instance_var': 'this is an instance var', 'class_var': 'e2 class var is actually an instance var'}



```python
# When we dereference an instance method, we get a *bound method*; the instance method bound to the instance:
e.instance_method
```




    <bound method Example.instance_method of <__main__.Example object at 0x10fe224e0>>




```python
# We can save a reference to the bound method and call it later and it will use the right instance

f = e.instance_method
e.instance_var = 'e\'s instance var'
f()
```




    "e's instance var"



There's a lot more to it than this, but this should give you some idea of how Python can support monkey-patching at run-time and other flexibility.

## Exceptions

You can raise an exception with the `raise` statement. You can give an instance of any class that derives from the `BaseException` class. You can catch exceptions using `try: except:`. If you want to get a reference to the exception, use `catch..as..`:


```python
try:
    raise Exception('The dude minds, man!')
except Exception as x:  # Exception is the type of exception to catch, x is the variable to catch it with.
    print(x)
    
# You can catch different types of exceptions, and you can use 'raise' on its own in the exception handling
# block to rethrow the exception.

def average(seq):
    "Compute the average of an iterable. "
    try:
        result = sum(seq) / len(seq)
    except ZeroDivisionError as e:
        return None
    except Exception:
        raise
    return result

print(average([]))
print(average(['cat']))
```

    The dude minds, man!
    None



    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-143-d2931b582ed8> in <module>()
         18 
         19 print(average([]))
    ---> 20 print(average(['cat']))
    

    <ipython-input-143-d2931b582ed8> in average(seq)
         10     "Compute the average of an iterable. "
         11     try:
    ---> 12         result = sum(seq) / len(seq)
         13     except ZeroDivisionError as e:
         14         return None


    TypeError: unsupported operand type(s) for +: 'int' and 'str'


## Iterators and Generators

A Python iterator is an object with a `__next__` method for sequential access, that raises a StopIteration when done.

A Python iterable is an object that defines a `__getitem__` method that can take sequential integer indices starting from 0 (so not necessarily random access) and raises an IndexError when done, or that has an `__iter__` method which returns an iterator.

See https://docs.python.org/3/tutorial/classes.html#iterators for more; here's an example from that link:


```python
class Reverse:
    """Iterator for looping over a sequence backwards."""
    def __init__(self, data):
        self.data = data
        self.index = len(data)

    def __iter__(self):
        return self

    def __next__(self):
        if self.index == 0:
            raise StopIteration
        self.index = self.index - 1
        return self.data[self.index]
    
for char in Reverse("spam"):
    print(char)
```

    m
    a
    p
    s


A generator is an easier way of creating an iterable, by simply writing a function that uses `yield` instead of `return`. For example, we can write a generator for Fibonacci numbers like this:


```python
def fibonacci():
    x = 1
    y = 0
    while True:
        lasty = y
        y += x
        x = lasty
        yield y
        
#f = fibonacci()
for i in fibonacci():
    print(i)
    if i > 100:
        break
```

    1
    1
    2
    3
    5
    8
    13
    21
    34
    55
    89
    144


It is worth noting that using these is very idiomatic to Python normally (see the *Fluent Python* book for example), but in the data science domain, this idiom is more commonly replaced by vectorizing. This web-based book goes deep into this different way of thinking: http://www.labri.fr/perso/nrougier/from-python-to-numpy/

## async/await

Python runs as a single-threaded process. That means things like I/O can slow things down a lot. It is possible to use multiple threads - there are several libraries for that - but even with a single thread big improvements are possible with async code. The details are beyond the scope of the bootcamp, but more info is available here: https://docs.python.org/3/library/asyncio-task.html. Recent changes in Python have made this much more powerful, flexible and easy to use, and there are some interesting third-party libraries like [Trio](https://trio.readthedocs.io/en/latest/index.html) that build on top of it. And if you don't like the standard way of doing this, there are alternatives like [Curio](https://curio.readthedocs.io/en/latest/).

## Type Annotations and Type Checking

Python has some mechanisms for doing optional type annotations. These can improve execution speed and there are some packages that can enforce type checking at run-time. It's not a bad idea to start using these but they're out of scope of this bootcamp. 

See https://docs.python.org/3/library/typing.html and http://mypy-lang.org/ for more.

## Structuring Your Projects

TODO

## Debugging

Python comes with a debugger, pdb. You can read about using it here: https://pymotw.com/3/pdb/

You can use pdb within a Jupyter notebook. Just add this code at the point you want to break execution and enter the debugger:
    
```python
import pdb; pdb.set_trace()
```

Once you're in the debugger, use the command `h` for help to see the commands available.

## Testing

TODO

## Packaging your Code

TODO


This guide has been written for people who are going to be writing most of their Python code in the Jupyter environment in which case distribution is not an issue. If you're wanting to build an installable package you can distribute, however, I think your best option is [PyInstaller](https://www.pyinstaller.org/). You should also structure your code files appropriately; you can find details of the recommended directory layout and necessary files that should be included [here](http://docs.python-guide.org/en/latest/writing/structure/).

## Generating Documentation

TODO

## The Standard Library

TODO

### The sys module

`sys.modules` is a dictionary of the currently imported modules. This can be large so let's just look at the names of the first few:


```python
import sys

list(sys.modules.keys())[:20]
```




    ['builtins',
     'sys',
     '_frozen_importlib',
     '_imp',
     '_warnings',
     '_thread',
     '_weakref',
     '_frozen_importlib_external',
     '_io',
     'marshal',
     'posix',
     'zipimport',
     'encodings',
     'codecs',
     '_codecs',
     'encodings.aliases',
     'encodings.utf_8',
     '_signal',
     '__main__',
     'encodings.latin_1']



`sys.path` is the path to look for imports:


```python
sys.path
```




    ['',
     '/Users/gram/anaconda/lib/python36.zip',
     '/Users/gram/anaconda/lib/python3.6',
     '/Users/gram/anaconda/lib/python3.6/lib-dynload',
     '/Users/gram/.local/lib/python3.6/site-packages',
     '/Users/gram/anaconda/lib/python3.6/site-packages',
     '/Users/gram/anaconda/lib/python3.6/site-packages/aeosa',
     '/Users/gram/anaconda/lib/python3.6/site-packages/IPython/extensions',
     '/Users/gram/.ipython']



### Dates and Times

It's worth briefly discussing Python's support for date and time operations as these are relevant to the exploratory data analysis we will be doing.

The standard library has two modules related to this area:

- `time`, which includes many low-level wrappers around platform C APIs. In particular, routines that convert between epoch time (from Jan 1, 1970) to the various time components found in a C `tm` struct. The most useful functions here are related to getting the system time zone and the `time.sleep()` function which pauses execution;
- `datetime` which provides a more high-level set of functions for dealing with dates, times, and time intervals; this is the module we will focus on here.

In addition to this, there are some good third-party libraries to be aware of, that, amongst other things, provide flexible date parsing operations from different formats. The most commonly used one, that extends the functionality of `datetime`, is `dateutil` (https://dateutil.readthedocs.io/en/stable/) but another that is growing in popularity is `arrow` (http://arrow.readthedocs.io/en/latest/) which provides a completely different approach with a very natural API. 

The `datetime` module (https://docs.python.org/3.6/library/datetime.html) defines five classes:

- `datetime`, combining a date and time
- `date`, a date only with no time component
- `time`, a time of day only, with no date component
- `timedelta`, an interval between two points in time
- `tzinfo`, a class that contains information about a time zone

### Handling JSON Data

Non-tabular data can be stored in dictionaries, which may be nested and contain lists. This is similar to JSON data on the web and in Javascript, and Python provides a `json` package for converting between these formats.


```python
import json

my_albums = [
    {
        'title': 'Tales of the Inexpressible',
        'artist': 'Shpongle',
        'year': 2001,
        'tracks': [
            { 'title': 'Dorset Perception', 'time': '8:12' },
            { 'title': 'Star Shpongled Banner', 'time': '8:23' },
            { 'title': 'A New Way to Say Hooray!', 'time': '8:32' },
            { 'title': 'Room 2ॐ', 'time': '5:05' },
            { 'title': 'My Head Feels Like a Frisbee', 'time': '8:52' },
            { 'title': 'Shpongleyes', 'time': '8:56' },
            { 'title': 'Once Upon the Sea of Blissful Awareness', 'time': '7:30' },
            { 'title': 'Around the World in a Tea Daze', 'time': '11:21' },
            { 'title': 'Flute Fruit', 'time': '2:09' },
        ],
    }
]

j = json.dumps(my_albums)  # Convert to JSON string
print(type(j))
j
```

    <class 'str'>





    '[{"title": "Tales of the Inexpressible", "artist": "Shpongle", "year": 2001, "tracks": [{"title": "Dorset Perception", "time": "8:12"}, {"title": "Star Shpongled Banner", "time": "8:23"}, {"title": "A New Way to Say Hooray!", "time": "8:32"}, {"title": "Room 2\\u0950", "time": "5:05"}, {"title": "My Head Feels Like a Frisbee", "time": "8:52"}, {"title": "Shpongleyes", "time": "8:56"}, {"title": "Once Upon the Sea of Blissful Awareness", "time": "7:30"}, {"title": "Around the World in a Tea Daze", "time": "11:21"}, {"title": "Flute Fruit", "time": "2:09"}]}]'




```python
p = json.loads(j)  # Convert from JSON string to Python object
print(type(p))
p
```

    <class 'list'>





    [{'artist': 'Shpongle',
      'title': 'Tales of the Inexpressible',
      'tracks': [{'time': '8:12', 'title': 'Dorset Perception'},
       {'time': '8:23', 'title': 'Star Shpongled Banner'},
       {'time': '8:32', 'title': 'A New Way to Say Hooray!'},
       {'time': '5:05', 'title': 'Room 2ॐ'},
       {'time': '8:52', 'title': 'My Head Feels Like a Frisbee'},
       {'time': '8:56', 'title': 'Shpongleyes'},
       {'time': '7:30', 'title': 'Once Upon the Sea of Blissful Awareness'},
       {'time': '11:21', 'title': 'Around the World in a Tea Daze'},
       {'time': '2:09', 'title': 'Flute Fruit'}],
      'year': 2001}]



### Logging

See https://opensource.com/article/17/9/python-logging for details on Python logging.

I recommend looking at Daiquiri, which builds on top of the standard logging library and make things easy:

https://julien.danjou.info/blog/python-logging-easy-with-daiquiri


```python
import sys
!{sys.executable} -m pip install daiquiri
```

    Collecting daiquiri
      Downloading daiquiri-1.3.0-py2.py3-none-any.whl
    Installing collected packages: daiquiri
    Successfully installed daiquiri-1.3.0
    [33mYou are using pip version 9.0.1, however version 9.0.3 is available.
    You should consider upgrading via the 'pip install --upgrade pip' command.[0m



```python
import logging
import daiquiri

daiquiri.setup(level=logging.INFO)

logger = daiquiri.getLogger("bootcamp")
logger.info("It works and logs to stderr by default with color!")
```

    2018-04-12 19:58:17,065 [13060] INFO     bootcamp: It works and logs to stderr by default with color!


## Cool Stuff

Notable Python features: https://github.com/tukkek/notablepython

Concise reference: https://github.com/mattharrison/Tiny-Python-3.6-Notebook

The Hitchhikers Guide to Python documents many best practices: http://docs.python-guide.org/en/latest/

Easily add progress bars to outer loops (works in Jupyter and console): https://pypi.python.org/pypi/tqdm

For anyone who wants to get really serious about Python, Mark Lutz's and David Beazley's books are good but some are dated, but the best book on the language itself is IMO "Fluent Python" by Luciano Ramalho. There are also many excellent talks at http://pyvideo.org/. 

Blog aggregator for Python: http://planetpython.org/


If you're interested in what the underlying Python byte code looks like for a function or class you can use the `dis` module:


```python
import dis

dis.dis(Widget)
```

    Disassembly of print_class:
     11           0 LOAD_GLOBAL              0 (print)
                  2 LOAD_GLOBAL              1 (Widget)
                  4 CALL_FUNCTION            1
                  6 POP_TOP
                  8 LOAD_CONST               1 (None)
                 10 RETURN_VALUE
    
    Disassembly of print_my_class:
      6           0 LOAD_GLOBAL              0 (print)
                  2 LOAD_FAST                0 (self)
                  4 LOAD_ATTR                1 (__class__)
                  6 CALL_FUNCTION            1
                  8 POP_TOP
                 10 LOAD_CONST               1 (None)
                 12 RETURN_VALUE
    


## Going Deeper



### Using Threads and Processes

See https://medium.com/@bfortuner/python-multithreading-vs-multiprocessing-73072ce5600b

### Extending Python with C code

See https://dbader.org/blog/python-ctypes-tutorial#.

### Functional Programming in Python

See https://docs.python.org/dev/howto/functional.html#iterators and http://coconut-lang.org/

### Making HTTP Requests and Parsing Responses

There are numerous ways to do this in Python, but the most commonly used libraries for these are `requests` (http://docs.python-requests.org/en/master/), which handles communications, and Beautiful Soup (https://www.crummy.com/software/BeautifulSoup/), which handles parsing HTML; look at those first before considering anything else as they are powerful, stable, mature and easy to use.


## So you want to write a...

My use of Python is mostly scripting repetitive tasks and data science so I am not an expert in any of the below, but these pointers should get you headed in the right direction:

### ...Web App

Wow! You are spoiled for choice! How on earth will be pick between the myriad options? Let me narrow it down for you: if you want a bare-bones framework a-la node.js, try [flask](http://flask.pocoo.org/) (or if even that is too heavyweight, [bottle](https://bottlepy.org/docs/dev/)). If you want everything plus the kitchen sink and a very opinionated chef, you will love [Django](https://www.djangoproject.com/); many big-name websites do. If you want something in-between, look at [Pyramid](https://trypyramid.com/), which would be my choice. If you're just building some REST server, take a look at [Eve](http://python-eve.org/) or [Hug](http://www.hug.rest/).

### ...Mobile Game or App

Python isn't your best bet for mobile, unfortunately, but people are trying. On an iPad, take a look at [Pythonista](http://omz-software.com/pythonista/), which is fantastic. Else your best bet is probably [Kivy](https://kivy.org/), but keep an eye on the up-and-coming [BeeWare](https://pybee.org/).

### ...Desktop Game

Your two main choices here are [PyGame](https://www.pygame.org/) (a wrapper over the very mature game library SDL), or [PyArcade](http://arcade.academy/), a newer library without the SDL dependency. If it was me I'd probably go with PyArcade; it's a more modern library and has some [great teaching material](http://arcade-book.readthedocs.io/en/latest/).

### ...Desktop GUI App

There are three main options here: [PyQt](https://riverbankcomputing.com/software/pyqt/intro), which requires a license for the commercial Qt library so I wouldn't recommend this for most cases, [wxPython](https://www.wxpython.org/) which is free and open source, and would be my recommendation, and [TkIntr](https://wiki.python.org/moin/TkInter), which is the "official" way to write GUI apps but IMO the results are ugly unless you take a lot of care. For something quick and dirty, TkIntr is the way to go, but if you want a native-looking polished cross-platform app, you should use one of the other two.

## Great Python Articles, Books and Courses

Michael Kennedy hosts two great podcasts (https://talkpython.fm/, and https://pythonbytes.fm/, with Brian Okken). He also has some high quality courses available at https://training.talkpython.fm/courses/all

There is a great collection of Python articles at https://medium.freecodecamp.org/python-collection-of-my-favorite-articles-8469b8455939

Below are a few of the best books on Python. 
These are affiliate links and I may earn a small commission:

<div>
<a target="_blank"  href="https://amzn.to/3ED0lQE" style="float:left;margin:50px"><img border="0" src="//ws-na.amazon-adsystem.com/widgets/q?_encoding=UTF8&MarketPlace=US&ASIN=1491946008&ServiceVersion=20070822&ID=AsinImage&WS=1&Format=_SL250_&tag=grahamwheel0b-20" ></a><img src="//ir-na.amazon-adsystem.com/e/ir?t=grahamwheel0b-20&l=am2&o=1&a=1491946008" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />

<a target="_blank"  href="https://amzn.to/32C133B" style="float:left;margin:50px"><img border="0" src="//ws-na.amazon-adsystem.com/widgets/q?_encoding=UTF8&MarketPlace=US&ASIN=1449340377&ServiceVersion=20070822&ID=AsinImage&WS=1&Format=_SL250_&tag=grahamwheel0b-20" ></a><img src="//ir-na.amazon-adsystem.com/e/ir?t=grahamwheel0b-20&l=am2&o=1&a=1449340377" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />

<a target="_blank"  href="https://amzn.to/3eCsPza" style="float:left;margin:50px"><img border="0" src="//ws-na.amazon-adsystem.com/widgets/q?_encoding=UTF8&MarketPlace=US&ASIN=1775093301&ServiceVersion=20070822&ID=AsinImage&WS=1&Format=_SL250_&tag=grahamwheel0b-20" ></a><img src="//ir-na.amazon-adsystem.com/e/ir?t=grahamwheel0b-20&l=am2&o=1&a=1775093301" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />
</div>




```python

```
