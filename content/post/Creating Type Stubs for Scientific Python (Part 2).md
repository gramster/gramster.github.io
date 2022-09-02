---
title: Creating Type Stubs for Scientific Python (Part 2)
date: 2022-08-29T16:47:00
author: Graham Wheeler
category: Programming
comments: enabled
---


Welcome back to this series on creating type stubs for scientific Python. In the last post we looked at using LibCST to generate skeleton type stubs, with a little bit of inference from value assignments. In this post we will dive into the process of using numpydoc-format docstrings.


## An Intro to numpydoc

The easiest way to get a feel for numpydoc-format docstrings is to look at an example:

```python
    def legend_elements(self, prop="colors", num="auto",
                        fmt=None, func=lambda x: x, **kwargs):
        """
        Create legend handles and labels for a PathCollection.

        Each legend handle is a `.Line2D` representing the Path that was drawn,
        and each label is a string what each Path represents.

        This is useful for obtaining a legend for a `~.Axes.scatter` plot;
        e.g.::

            scatter = plt.scatter([1, 2, 3],  [4, 5, 6],  c=[7, 2, 3])
            plt.legend(*scatter.legend_elements())

        creates three legend elements, one for each color with the numerical
        values passed to *c* as the labels.

        Also see the :ref:`automatedlegendcreation` example.

        Parameters
        ----------
        prop : {"colors", "sizes"}, default: "colors"
            If "colors", the legend handles will show the different colors of
            the collection. If "sizes", the legend will show the different
            sizes. To set both, use *kwargs* to directly edit the `.Line2D`
            properties.
        num : int, None, "auto" (default), array-like, or `~.ticker.Locator`
            Target number of elements to create.
            If None, use all unique elements of the mappable array. If an
            integer, target to use *num* elements in the normed range.
            If *"auto"*, try to determine which option better suits the nature
            of the data.
            The number of created elements may slightly deviate from *num* due
            to a `~.ticker.Locator` being used to find useful locations.
            If a list or array, use exactly those elements for the legend.
            Finally, a `~.ticker.Locator` can be provided.
        fmt : str, `~matplotlib.ticker.Formatter`, or None (default)
            The format or formatter to use for the labels. If a string must be
            a valid input for a `.StrMethodFormatter`. If None (the default),
            use a `.ScalarFormatter`.
        func : function, default: ``lambda x: x``
            Function to calculate the labels.  Often the size (or color)
            argument to `~.Axes.scatter` will have been pre-processed by the
            user using a function ``s = f(x)`` to make the markers visible;
            e.g. ``size = np.log10(x)``.  Providing the inverse of this
            function here allows that pre-processing to be inverted, so that
            the legend labels have the correct values; e.g. ``func = lambda
            x: 10**x``.
        **kwargs
            Allowed keyword arguments are *color* and *size*. E.g. it may be
            useful to set the color of the markers if *prop="sizes"* is used;
            similarly to set the size of the markers if *prop="colors"* is
            used. Any further parameters are passed onto the `.Line2D`
            instance. This may be useful to e.g. specify a different
            *markeredgecolor* or *alpha* for the legend handles.

        Returns
        -------
        handles : list of `.Line2D`
            Visual representation of each element of the legend.
        labels : list of str
            The string labels for elements of the legend.
        """
        ...
```

You can see there is some preamble, then a 'Parameters' section and a 'Returns' section. There's actually several other sections that may be present, and even these two may or may not exist. The above is an example of what I would call a good input to our problem.

You'll see that the Returns section actually lists two returns, 'handles' and 'labels'. At least for matplotlib, that means a tuple is returned. If you look at the parameters, you can see that there might be a description of the default value; we can discard that we we get the defaults from the signature. There may be multiple types listed, as in:

```
        num : int, None, "auto" (default), array-like, or `~.ticker.Locator`
```

Note the backticks around the last option; numpydoc uses restructured text format so there may be formatting we need to strip out.

The docstring can specify is an API is deprecated, using text like:

```
.. deprecated:: 1.6.0
          `ndobj_old` will be removed in NumPy 2.0.0, it is replaced by
          `ndobj_new` because the latter works also with array subclasses.
```

This is useful if we want to remove such APIs from the stubs (perhaps as a future enhancement).

Each section title must be underlined with hyphens, and each section is optional. Sections are ordered. The overall format can be illustrated by the below 'meta-example':

```
    One-line summary.
    
    Deprecation section.    
    
    Extended (multi-line) summary.
    
    Parameters
    ----------
    x  A parameter with no type info (note no ':')
    y : int
       A parameter with type info
    z: int, optional
       An optional keyword parameter (for default see signature)
    a : bool, default True
    b : bool, default=True
    c : bool, default: True
       Optional keyword parameters with documented defaults.
       Any of those syntaxes are allowed
    order : {'first', 'last'}
       A parameter that can only take on a few values
    x1, x2 : array_like
       Two parameters with same types
    *args : tuple
       Variable length additional positional arguments
    **kwargs : dict, optional
       Additional keyword arguments.

    Attributes
    ----------
    Only for class docstrings, describes non-method attributes
    of the class, in same format as Parameters section.
    
    Methods
    -------
    For classes with many methods of which only a few
    are relevant. Format is signature on one line, description indented below.
    
    Returns
    -------
    int
       Returned values can take same format as parameters,
       or can be specified just as a type with no 
       name. The type must always be specified.
       
    Yields
    ------
    
    For generators; takes the same format as the Returns
    section.
    
    Receives
    --------
    Parameters passed to a generator’s .send() method.
    
    Other Parameters
    ----------------
    Infrequently used parameters for functions with
    large numbers of parameters.
    
    Raises
    ------
    Which errors get raised and under what conditions.
    
    Warns
    -----
    Which warnings get raised and under what conditions.    
    
    Warnings
    --------
    Cautions to the user.
    
    See Also
    --------
    Other relevant functions.
    
    Notes
    -----
    Supplementary info like algorithm details
    
    References
    ----------
    A bibliography section
    
    Examples
    --------
    Examples of usage.
    
```

`self` is not included in the Parameters section of class methods.

It should be noted that numpydoc is a documentation convention meant  for human consumption. This means that while parameters are frequently documented and the documentation includes type information, it is not the same as formal Python type annotations. In order to go from a type described in a numpydoc string to a Python type annotation, we're going to have to do work.

## The Approach

When I generated the matplotlib stubs, I wrote a parser that was specific to matplot lib. It was hacky and ugly, because I was trying to automate as much as possible. That meant some degree of 'standardized' munging, e.g. where there was more than one type described, separated by "," or "or", I could turn that into a union. There were a lot of cases that either couldn't be that easily handled or were infrequent enough to not merit spending a lot of time on, and for those I resorted to a mapping in a dictionary.

I don't want to reuse that ugly code here; I'll try to do something a bit cleaner, but in turn, I'm going to rely a lot more on a mapping approach, which requires a human to create the map. But we can help with this process, as well as make it generalize better to other packages, by writing some code to create an initial version of the map. So I am going to tackle the problem in three stages, two of which are automated:

- an 'analyze' stage that extracts all the types, buckets them by frequency, does a best-effort attempt at cleaning them up, and then writes the resulting mapping to a file
- a 'human in the loop' stage where that file is inspected and cleaned up by a human
- an 'apply' stage where we generate stubs using the skeleton we developed in the last post, but making use of the map we created to insert types


### Parsing the Docstrings

As I mentioned, I wrote a parser for matplotlib, and while I could use it, its not the cleanest code. And once I learned about numpydoc, Michael Droettboom, the creator of matplotlib and a member of my team, pointed out to me that there is a sphinx extension called "napoleon" that [parses these docstrings](https://github.com/sphinx-doc/sphinx/blob/5.x/sphinx/ext/napoleon/docstring.py). So I am going to do like all great artists and steal in the code below. An advantage of going this route is that napoleon also supports Google docstring format, so I can easily extend the parser later for that if I choose.


```python
import abc
from ast import Num
import collections
import re
from typing import Any, Callable


class Deque(collections.deque):
    """
    A subclass of deque that adds `.Deque.get` and `.Deque.next` methods.
    """

    sentinel = object()

    def get(self, n: int) -> Any:
        """
        Return the nth element of the stack, or ``self.sentinel`` if n is
        greater than the stack size.
        """
        return self[n] if n < len(self) else self.sentinel

    def next(self) -> Any:
        if self:
            return super().popleft()
        else:
            raise StopIteration


class DocstringParserBase(abc.ABC):
    """ Methods that are the same in Napoleon for Google format
        and Numpydoc format I put in this class. That will make 
        it easier eventually to add Google format support.
    """
    _single_colon_regex = re.compile(r'(?<!:):(?!:)')
    _xref_or_code_regex = re.compile(
        r'((?::(?:[a-zA-Z0-9]+[\-_+:.])*[a-zA-Z0-9]+:`.+?`)|'
        r'(?:``.+?``))')
    _remove_default_val = re.compile(r'^(.*),[ \t]*default[ \t]*.*$')
    _remove_optional = re.compile(r'^(.*),[ \t]*[Oo]ptional$')

    def __init__(self):
        self._attributes = None
        self._parameters = None
        self._returns = None
        self._is_in_section = False
        self._section_indent = 0
        self._lines: Deque = Deque()
        self._sections: dict[str, Callable] = {}

    @abc.abstractmethod
    def _is_section_break(self) -> bool:
            ...

    @abc.abstractmethod
    def _is_section_header(self) -> bool:
        ...

    def _is_indented(self, line: str, indent: int = 1) -> bool:
        """ Check if a line is at least <indent> indented """
        for i, s in enumerate(line):
            if i >= indent:
                return True
            elif not s.isspace():
                return False
        return False

    def _get_indent(self, line: str) -> int:
        """ Get indentation for a single line. """
        for i, s in enumerate(line):
            if not s.isspace():
                return i
        return len(line)

    def _get_current_indent(self, peek_ahead: int = 0) -> int:
        line = self._lines.get(peek_ahead)
        while line is not self._lines.sentinel:
            if line:
                return self._get_indent(line)
            peek_ahead += 1
            line = self._lines.get(peek_ahead)
        return 0

    def _consume_empty(self) -> None:
        """ Advance through any empty lines. """
        line = self._lines.get(0)
        while self._lines and not line:
            self._lines.next()
            line = self._lines.get(0)

    def _consume_indented_block(self, indent: int = 1) -> None:
        line = self._lines.get(0)
        while (
            not self._is_section_break() and (not line or self._is_indented(line, indent))
        ):
            self._lines.next()
            line = self._lines.get(0)

    def _consume_to_next_section(self) -> None:
        """ Consume a whole section. """
        self._consume_empty()
        while not self._is_section_break():
            self._lines.next()

    def _consume_section_header(self) -> str:
        section = self._lines.next()
        stripped_section = section.strip().strip(':')
        if stripped_section.lower() in self._sections:
            section = stripped_section
            self._lines.next() # consume ----- part
        return section

    def _skip_section(self, section: str):
        self._consume_to_next_section()

    def _partition_field_on_colon(self, line: str) -> tuple[str, str, str]:
        before_colon = []
        after_colon = []
        colon = ''
        found_colon = False
        for i, source in enumerate(DocstringParserBase._xref_or_code_regex.split(line)):
            if found_colon:
                after_colon.append(source)
            else:
                m = DocstringParserBase._single_colon_regex.search(source)
                if (i % 2) == 0 and m:
                    found_colon = True
                    colon = source[m.start(): m.end()]
                    before_colon.append(source[:m.start()])
                    after_colon.append(source[m.end():])
                else:
                    before_colon.append(source)

        return ("".join(before_colon).strip(),
                colon,
                "".join(after_colon).strip())


    @abc.abstractmethod
    def _consume_field(self, prefer_type: bool = False
                       ) -> tuple[str, str]: ...

    def _consume_fields(self, parse_type: bool = True, prefer_type: bool = False,
                        multiple: bool = False) -> list[tuple[str, str]]:
        self._consume_empty()
        fields = []
        while not self._is_section_break():
            name, typ = self._consume_field(prefer_type)
            
            # Remove , optional ... from end
            m = DocstringParserBase._remove_optional.match(typ)
            if m:
                typ = m.group(1)
            # Remove , default ... from end
            m = DocstringParserBase._remove_default_val.match(typ)
            if m:
                typ = m.group(1)
                
            # Remove (default) from within
            typ = typ.replace(' (default)', '')
            
            if multiple and name:
                for n in name.split(","):
                    fields.append((n.strip(), typ))
            elif name or normalized:
                fields.append((name, typ))
        return fields

    @abc.abstractmethod
    def _parse_returns_section(self, section: str) -> None:
        ...

    def _parse_attributes_section(self, section: str) -> None:
        self._attributes = self._consume_fields(multiple=True)

    def _parse_parameters_section(self, section: str) -> None:
        self._parameters = self._consume_fields(multiple=True)

    def _prep_parser(self, docstring: str) -> None:
        self._attributes = None
        self._parameters = None
        self._returns = None
        self._is_in_section = False
        self._section_indent = 0
        self._lines = Deque(map(str.rstrip, docstring.splitlines()))

    def parse(self, docstring: str) -> tuple[list[tuple[str, str, str]]|None, ...]:
        self._prep_parser(docstring)
        self._consume_to_next_section()
        while self._lines:
            section = self._consume_section_header()
            if not section:
                # IMO this shouldn't happen but does; dig into it
                # later
                self._consume_to_next_section()
                continue

            self._is_in_section = True
            self._section_indent = self._get_current_indent()
            self._sections[section.lower()](section)
            self._is_in_section = False
            self._section_indent = 0

        return self._parameters, self._returns, self._attributes


class NumpyDocstringParser(DocstringParserBase):

    _numpy_section_regex = re.compile(r'^[=\-`:\'"~^_*+#<>]{2,}\s*$')
    _remove_default_val = re.compile(r'^(.*),[ \t]*default[ \t]*.*$')
    _restricted_val = re.compile(r'^(.*){(.*)}(.*)$')
    _tuple = re.compile(r'^(.*)\((.*)\)(.*)$')

    def __init__(self): 
        super().__init__()
        self._sections: dict[str, Callable] = {
            'attributes': self._parse_attributes_section,
            'examples': self._skip_section,
            'methods': self._skip_section,
            'notes': self._skip_section,
            'other parameters': self._skip_section,
            'parameters': self._parse_parameters_section,
            'receives': self._skip_section,
            'returns': self._parse_returns_section,
            'raises': self._skip_section,
            'references': self._skip_section,
            'see also': self._skip_section,
            'warnings': self._skip_section,
            'warns': self._skip_section,
            'yields': self._skip_section,
        }

    def _is_section_header(self) -> bool:
        section, underline = self._lines.get(0), self._lines.get(1)
        section = section.strip().lower()
        if section in self._sections:
            if isinstance(underline, str):
                return bool(NumpyDocstringParser._numpy_section_regex.match(underline.strip()))

        return False

    def _is_section_break(self) -> bool:
        line1, line2 = self._lines.get(0), self._lines.get(1)
        return (not self._lines or
                self._is_section_header() or
                ['', ''] == [line1, line2] or
                (self._is_in_section and
                    line1 and
                    not self._is_indented(line1, self._section_indent)))

    def _consume_field(self, prefer_type: bool = False
                       ) -> tuple[str, str]:
        line = self._lines.next()
        
        _name, _, _type = self._partition_field_on_colon(line)
        _name, _type = _name.strip(), _type.strip()

        if prefer_type and not _type:
            _type, _name = _name, _type

        # Consume the description
        self._consume_indented_block(self._get_indent(line) + 1)
        return _name, _type

    def _parse_returns_section(self, section: str) -> None:
        self._returns = self._consume_fields(prefer_type=True)

```

The code is straightforward enough. We can write a simple tester:

```python
    x = <the sample docstring shown earlier>
    rtn = NumpyDocstringParser().parse(x)
    for i, k in enumerate(['Params', 'Returns', 'Attrs']):
        sec = rtn[i]
        if sec:
            print(k)
            print('-' * len(k))
            for (n, r, t) in sec:
                print(f'  name {n}: type {t}')

```

And we get the output:

```
Params
------
  name prop: type {"colors", "sizes"}
  name num: type int, None, "auto" , array-like, or `~.ticker.Locator`
  name fmt: type str, `~matplotlib.ticker.Formatter`, or None
  name func: type function
  name **kwargs: type 
Returns
-------
  name handles: type list of `.Line2D`
  name labels: type list of str
```

Of course, this has just got the raw fields out of the docstring (minus default/optional bits); there's no normalization or conversion to something closer to Python type annotations yet. In the next section we will work on addressing that.

### Best-Effort Type Cleaning

Let's first focus on our test case.

The first thing we can do is throw away anything that starts with ", default ...", as we will get the default from the definition itself. For the `num` parameter, the default was specified differently, by annotating one of the options with "(default)", so we can erase that string too. We then are left with comma-separated strings (where the last element is separated by "or" instead). However, we have the constrained parameter `prop` that has a list of possible values, and these are comma separated too. Plus some types may be tuples, enclosed in parentheses. So we should start with such compound types and then after that we can turn the lists of types into unions. At least in matplotlib, some types start with '.' (meaning they are classes defined in the same file, I believe); we can strip those off. And while we're at it, some start with '~', which seems redundant too (I'm not sure what it is supposed to denote; I'll try find out). Let's add a function `normalize_type` to do all this:

```python
import re

_restricted_val = re.compile(r'^(.*){(.*)}(.*)$')
_tuple1 = re.compile(r'^(.*)\((.*)\)(.*)$')  # using ()
_tuple2 = re.compile(r'^(.*)\[(.*)\](.*)$')  # using []
_sequence_of = re.compile(r'^(List|list|Sequence|sequence|Array|array) of ([A-Za-z0-9\._~`]+)$')
_tuple_of = re.compile(r'^(Tuple|tuple) of ([A-Za-z0-9\._~`]+)$')


def normalize_type(s: str) -> str:
    # Handle a restricted value set
    m = _restricted_val.match(s)
    l = None
    if m:
        s = m.group(1) + m.group(3)
        l = 'Literal[' + m.group(2) + ']'

    # Handle tuples in [] or (). Right now we can only handle one per line;
    # need to fix that.

    m = _tuple1.match(s)
    if not m:
        m = _tuple2.match(s)
    t = None
    if m:
        s = m.group(1) + m.group(3)
        t = 'tuple[' + m.group(2) + ']'

    # Now look at list of types. First replace ' or ' with a comma.
    # This is a bit dangerous as commas may exist elsewhere but 
    # until we find the failure cases we don't know how to address 
    # them yet.
    s = s.replace(' or ', ',')

    # Get the alternatives
    parts = s.split(',')

    def normalize_one(s):
        """ Do some normalizing of a single type. """
        s = s.strip()
        s = s.replace('`', '')  # Removed restructured text junk

        # Handle collections like 'list of...', 'array of ...' ,etc
        m = _sequence_of.match(s)
        if m:
            return f'Sequence[{normalize_one(m.group(2))}]'
        m = _tuple_of.match(s)
        if m:
            return f'tuple[{normalize_one(m.group(2))}, ...]'

        # Handle literal numbers and strings
        if not (s.startswith('"') or s.startswith("'")):
            try:
                float(s)
            except ValueError:
                while s.startswith('.') or s.startswith('~'):
                    s = s[1:]
                return s
        return 'Literal[' + s + ']'
        
    # Create a union from the normalized alternatives
    s = '|'.join(normalize_one(p) for p in parts if p.strip())

    # Add back our constrained value literal, if it exists
    if s and l:
        s += '|' + l
    elif l:
        s = l

    # Add back our tuple, if it exists
    if s and t:
        s += '|' + t
    elif t:
        s = t

    return s

```    

It's not a thing of beauty at all, and I'm not proud of it, but it's a good start for us to explore in more detail what other cases there might be.

### Writing the Map File

For the map file, we are going to import a module, look at all of the docstrings, pull out the normalized types, and add them to a set where we also maintain counts. We can then output this in order of frequency. This will quickly give us much more data to look at to see what we are dealing with.

First, let's refactor our earlier `stub_module` method to extract a useful utility we will need again. I've enhanced it at the same time to be able to do per-file outputs (like the stub files) or per-module outputs (which we will use for analysis). In the latter case we will maintain a state object that we post-process at the end:

```python
import glob
import importlib
import inspect
import os
from types import ModuleType
from typing import Callable


def get_module_and_files(m: str) -> tuple[ModuleType|None, list[str]]:
    try:
        mod = importlib.import_module(m)
    except Exception as e:
        print(f'Could not import module {m}: {e}')
        return None, []
    file = inspect.getfile(mod)
    if file.endswith("/__init__.py"):
        # Get the parent directory and all the files in that directory
        folder = file[:-12]
        files = glob.glob(folder + "/*.py")
    else:
        files = [file]
    return mod, files


def process_module(m: str, processor: Callable, 
        targeter: Callable,
        post_processor: Callable|None = None, 
        state: object = None,
        **kwargs):
    mod, files = get_module_and_files(m)
    if not mod:
        return

    result = None
    if state is None:
        state = {}

    for file in files:
        try:
            with open(file) as f:
                source = f.read()
        except Exception as e:
            print(f"Failed to read {file}: {e}")
            continue

        result = processor(mod, file, source, state, **kwargs)
        if post_processor is None:
            if result is None:
                print(f"Failed to process {file}")
                continue
            else:
                target = targeter(file)
                folder = target[: target.rfind("/")]
                os.makedirs(folder, exist_ok=True)
                with open(target, "w") as f:
                    f.write(result)
        print(f"Processed file {file}")

    if post_processor:
        result = post_processor(m, state)
        target = targeter(m)
        folder = target[: target.rfind("/")]
        os.makedirs(folder, exist_ok=True)
        with open(target, "w") as f:
            f.write(result)

`stub_module` then becomes:

```python
def _stub(mod: ModuleType, fname: str, source: str, **kwargs):
    return patch_source(source, **kwargs)

def _targeter(fname: str) -> str:
    return "typings/" + fname[fname.find("/site-packages/") + 15 :] + "i"

def stub_module(m: str, strip_defaults: bool = False):
    process_module(m, _stub, _targeter, strip_defaults=strip_defaults)


```

We're also going to want to keep track of function and class nesting in the new transformer so let's extract that out to a new base clase all our transformers can inherit from.

```python
import libcst as cst


class BaseTransformer(cst.CSTTransformer):
    def __init__(self, strip_defaults=False):
        self._in_class_count = 0
        self._in_function_count = 0

    def in_class(self)-> bool:
        return self._in_class_count > 0

    def in_function(self)-> bool:
        return self._in_function_count > 0

    def at_top_level(self):
        return not(self.in_class() or self.in_function())

    def at_top_level_class_level(self) -> bool:
        return self._in_class_count == 1 and not self.in_function()

    def in_method(self) -> bool:
        # Strictly speaking this can happen if we define a class
        # in a top-level function too.
        # TODO: figure out how to detect that. It probably
        # doesn't matter though so punting for now.
        return self.in_class() and self.in_function()

    def at_top_level_function_level(self) -> bool:
        return not self.in_class() and self._in_function_count == 1

    def visit_ClassDef(self, node: cst.ClassDef) -> bool:
        assert(self._in_class_count <= 1)
        self._in_class_count += 1
        # No point recursing if we are at nested function level
        # or this is a nested class.
        return self._in_class_count == 1

    def leave_ClassDef(self, original_node: cst.ClassDef, updated_node: cst.ClassDef) -> cst.CSTNode:
        self._in_class_count -= 1
        return updated_node

    def visit_FunctionDef(self, node: cst.FunctionDef) -> bool:
        assert(self._in_function_count <= 1)
        self._in_function_count += 1
        # No point recursing if we are at nested function level
        return self._in_function_count == 1

    def leave_FunctionDef(
        self, original_node: cst.FunctionDef, updated_node: cst.FunctionDef
    ) -> cst.CSTNode:
        self._in_function_count -= 1  
        return updated_node

```

Now we can create the analyzer. I could just have used importlib to import the module and then introspected to find all the docstrings, but I'm still going to lean on LibCST; that may be useful later and if nothing else makes it easy to switch between writing map files at the file level or the module level (although we may only need the module level; in fact we'll probably end up doing mapping at the package level eventually).

I'm also going to collect all the classes and their locations while I am at it; this will be useful to know what relative imports may need to be added to the stubs later.


```python
from ast import Num
from collections import Counter
import inspect
from types import ModuleType
import libcst as cst
from .basetransformer import BaseTransformer
from .utils import process_module
from .parser import NumpyDocstringParser
from .normalize import normalize_type

class AnalyzingTransformer(BaseTransformer):

    def __init__(self, mod: ModuleType, fname: str, counter: Counter,
            imports: dict):
        super().__init__()
        self._mod = mod
        i = fname.find('site-packages')
        if i > 0:
            # Strip off the irrelevant part of the path
            self._fname = fname[i+14:]
        else:
            self._fname = fname
        self._classname = ''
        self._parser = NumpyDocstringParser()
        self._counter = counter
        self._imports = imports

    def _analyze_obj(self, obj, context: str):
        doc = None
        if obj:
            doc = inspect.getdoc(obj)
        if not doc:
            return
        rtn = self._parser.parse(doc)
        for section in rtn:
            if section:
                for _, typ in section:
                    self._counter[typ] += 1

    @staticmethod
    def get_top_level_obj(mod: ModuleType, fname: str, oname: str):
        try:
            return mod.__dict__[oname]
        except KeyError as e:
            try:
                submod = fname[fname.rfind('/')+1:-3]
                return mod.__dict__[submod].__dict__[oname]
            except Exception:
                print(f'{fname}: Could not get obj for {oname}')
                return None

    def visit_ClassDef(self, node: cst.ClassDef) -> bool:
        if self.at_top_level():
            self._classname = node.name.value
            self._imports[self._classname] = self._fname
            obj = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, node.name.value)
            self._analyze_obj(obj, self._classname)
        return super().visit_ClassDef(node)

    def visit_FunctionDef(self, node: cst.FunctionDef) -> bool:
        name = node.name.value
        obj = None
        context = ''
        if self.at_top_level():
            context = name
            obj = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, name)
        elif self.at_top_level_class_level():
            context = f'{self._classname}.{name}'
            parent = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, self._classname)
            if parent:
                if name in parent.__dict__:
                    obj = parent.__dict__[name]
                else:
                    print(f'{self._fname}: Could not get obj for {self._classname}.{name}')
        self._analyze_obj(obj, context)
        return super().visit_FunctionDef(node)


def _analyze(mod: ModuleType, fname: str, source: str, state: tuple, **kwargs):
    try:
        cstree = cst.parse_module(source)
    except Exception as e:
        return None
    try:
        patcher = AnalyzingTransformer(mod, fname, 
            counter=state[0], 
            imports = state[1])
        cstree.visit(patcher)
    except:  # Exception as e:
        # Note: I know that e is undefined below; this actually lets me
        # successfully see the stack trace from the original excception
        # as traceback.print_exc() was not working for me.
        print(f"Failed to analyze file: {e}")
        return None
    return state

def _post_process(m: ModuleType, state: tuple):
    result = ''
    freq: Counter = state[0]
    for typ, cnt in freq.most_common():
        result += f'{cnt}#{typ}#{normalize_type(typ)}\n'
    return result


def _targeter(m: str) -> str:
    """ Turn module name into map file name """
    return f"analysis/{m}.typ"


def analyze_module(m: str):
    process_module(m, _analyze, _targeter, post_processor=_post_process, 
        state=(Counter(), {}, {}))


```

## Testing the Analysis

We can now run this on a module. Below is the output from analyzing `matplotlib.axes`. Each line is a count followed by the original type and the normalized type. Later we will have the opportunity to edit this file to correct the normalized types before they get injected.

```
100#float#float
94#bool#bool
35#array-like#array-like
27#int#int
25#str#str
23#dict#dict
23#float or array-like#float|array-like
19##
14#1-D array#1-D array
10#float or None#float|None
10#1D or 2D array-like#1D|2D array-like
9#(float, float)#tuple[float, float]
9#bool or None#bool|None
8#indexable object#indexable object
7#color#color
7#`~matplotlib.lines.Line2D`#matplotlib.lines.Line2D
7#callable or ndarray#callable|ndarray
7#{'default', 'onesided', 'twosided'}#Literal['default', 'onesided', 'twosided']
6#list of `.Line2D`#Sequence[Line2D]
6#list#list
6#array (length N) or scalar#array|scalar|tuple[length N]
5#{'center', 'left', 'right'}#Literal['center', 'left', 'right']
5#str or `~matplotlib.colors.Colormap`#str|matplotlib.colors.Colormap
5#`~matplotlib.colors.Normalize`#matplotlib.colors.Normalize
5#1-D array or sequence#1-D array|sequence
4#(M, N) array-like#array-like|tuple[M, N]
4#{'none', 'mean', 'linear'} or callable#callable|Literal['none', 'mean', 'linear']
4#Transform#Transform
4#{'center', 'top', 'bottom', 'baseline', 'center_baseline'}#Literal['center', 'top', 'bottom', 'baseline', 'center_baseline']
3#`.Bbox`#Bbox
3#{'top', 'bottom', 'left', 'right'} or float#float|Literal['top', 'bottom', 'left', 'right']
3#{'mask', 'clip'}#Literal['mask', 'clip']
3#callable#callable
3#{'pre', 'post', 'mid'}#Literal['pre', 'post', 'mid']
3#`.BarContainer`#BarContainer
3#float or array-like, shape (n, )#float|array-like|shape|tuple[n, ]
3#color or color sequence#color|color sequence
3#array (length N)#array|tuple[length N]
3#array of bool (length N)#Sequence[bool]|tuple[length N]
3#`.PolyCollection`#PolyCollection
3#2D array-like#2D array-like
3#str or None#str|None
3#array-like, shape (n, )#array-like|shape|tuple[n, ]
3#`~.axes.Axes`#axes.Axes
3#{'both', 'x', 'y'}#Literal['both', 'x', 'y']
2#`.Text`#Text
2#list of str#Sequence[str]
2#[x0, y0, width, height]#tuple[x0, y0, width, height]
2#`.Transform`#Transform
2#`.Axes`#Axes
2#`.patches.Rectangle`#patches.Rectangle
2#4-tuple of `.patches.ConnectionPatch`#4-tuple of .patches.ConnectionPatch
2#2-tuple of func, or Transform with an inverse#2-tuple of func|Transform with an inverse
2#axes._secondary_axes.SecondaryAxis#axes._secondary_axes.SecondaryAxis
2#str or `.Artist` or `.Transform` or callable or (float, float)#str|Artist|Transform|callable|tuple[float, float]
2#`~matplotlib.patches.Polygon`#matplotlib.patches.Polygon
2#list of colors#Sequence[colors]
2#{'solid', 'dashed', 'dashdot', 'dotted'}#Literal['solid', 'dashed', 'dashdot', 'dotted']
2#`~matplotlib.collections.LineCollection`#matplotlib.collections.LineCollection
2#array-like or scalar#array-like|scalar
2#sequence#sequence
2#array (length ``2*maxlags+1``)#array|tuple[length ``2*maxlags+1``]
2#array  (length ``2*maxlags+1``)#array|tuple[length ``2*maxlags+1``]
2#`.LineCollection` or `.Line2D`#LineCollection|Line2D
2#`.Line2D` or None#Line2D|None
2#array-like of length n#array-like of length n
2#{'center', 'edge'}#Literal['center', 'edge']
2#1D array-like#1D array-like
2#float or array-like, shape(N,) or shape(2, N)#float|array-like|shape(N|)|shape|tuple[2, N]
2#int or (int, int)#int|tuple[int, int]
2#Array or a sequence of vectors.#Array|a sequence of vectors.
2#list of dicts#Sequence[dicts]
2#{'linear', 'log'}#Literal['linear', 'log']
2#{'width', 'height', 'dots', 'inches', 'x', 'y', 'xy'}#Literal['width', 'height', 'dots', 'inches', 'x', 'y', 'xy']
2#{'upper', 'lower'}#Literal['upper', 'lower']
2#`~matplotlib.image.AxesImage`#matplotlib.image.AxesImage
2#{'none', None, 'face', color, color sequence}#Literal['none', None, 'face', color, color sequence]
2#tuple or array-like#tuple|array-like
2#int or array-like#int|array-like
2#`~.contour.QuadContourSet`#contour.QuadContourSet
2#{'vertical', 'horizontal'}#Literal['vertical', 'horizontal']
2#2D array#2D array
2#1D array#1D array
2#1-D arrays or sequences#1-D arrays|sequences
2#{'default', 'linear', 'dB'}#Literal['default', 'linear', 'dB']
2#float greater than -0.5#float greater than -0.5
2#bool or 'line'#bool|Literal['line']
2#{'major', 'minor', 'both'}#Literal['major', 'minor', 'both']
2#{'x', 'y', 'both'}#Literal['x', 'y', 'both']
2#{"linear", "log", "symlog", "logit", ...} or `.ScaleBase`#ScaleBase|Literal["linear", "log", "symlog", "logit", ...]
2#`.MouseButton`#MouseButton
2#Axes#Axes
1#{'center', 'left', 'right'}, str#str|Literal['center', 'left', 'right']
1#sequence of `.Artist`#Sequence[Artist]
1#`~matplotlib.legend.Legend`#matplotlib.legend.Legend
1#number#number
1#ax#ax
1#`.Annotation`#Annotation
1#`.Line2D`#Line2D
1#array-like or list of array-like#array-like|list of array-like
1#{'horizontal', 'vertical'}#Literal['horizontal', 'vertical']
1#color or list of colors#color|Sequence[colors]
1#str or tuple or list of such values#str|tuple|list of such values
1#list of `.EventCollection`#Sequence[EventCollection]
1#timezone string or `datetime.tzinfo`#timezone string|datetime.tzinfo
1#{'edge', 'center'}#Literal['edge', 'center']
1#list of `.Text`#Sequence[Text]
1#sequence of tuples (*xmin*, *xwidth*)#Sequence[tuples]|tuple[*xmin*, *xwidth*]
1#(*ymin*, *yheight*)#tuple[*ymin*, *yheight*]
1#`~.collections.BrokenBarHCollection`#collections.BrokenBarHCollection
1#`.StemContainer`#StemContainer
1#None or str or callable#None|str|callable
1#`.ErrorbarContainer`#ErrorbarContainer
1#float or (float, float)#float|tuple[float, float]
1#color or sequence or sequence of color or None#color|sequence|Sequence[color]|None
1#color or sequence of color or {'face', 'none'} or None#color|Sequence[color]|None|Literal['face', 'none']
1#c#c
1#array(N, 4) or None#array|None|tuple[N, 4]
1#edgecolors#edgecolors
1#array-like or list of colors or color#array-like|Sequence[colors]|color
1#`~.markers.MarkerStyle`#markers.MarkerStyle
1#{'face', 'none', *None*} or color or sequence of color#color|Sequence[color]|Literal['face', 'none', *None*]
1#`~matplotlib.collections.PathCollection`#matplotlib.collections.PathCollection
1#'log' or int or sequence#Literal['log']|int|sequence
1#int > 0#int > 0
1#4-tuple of float#4-tuple of float
1#`~matplotlib.collections.PolyCollection`#matplotlib.collections.PolyCollection
1#{'full', 'left', 'right'}#Literal['full', 'left', 'right']
1#`.FancyArrow`#FancyArrow
1#`matplotlib.quiver.Quiver`#matplotlib.quiver.Quiver
1#{'axes', 'figure', 'data', 'inches'}#Literal['axes', 'figure', 'data', 'inches']
1#{'N', 'S', 'E', 'W'}#Literal['N', 'S', 'E', 'W']
1#{'uv', 'xy'} or array-like#array-like|Literal['uv', 'xy']
1#{'tail', 'mid', 'middle', 'tip'}#Literal['tail', 'mid', 'middle', 'tip']
1#`~matplotlib.quiver.Quiver`#matplotlib.quiver.Quiver
1#{'tip', 'middle'} or float#float|Literal['tip', 'middle']
1#bool or array-like of bool#bool|array-like of bool
1#`~matplotlib.quiver.Barbs`#matplotlib.quiver.Barbs
1#sequence of x, y, [color]#Sequence[x]|y|tuple[color]
1#list of `~matplotlib.patches.Polygon`#Sequence[matplotlib.patches.Polygon]
1#{{'pre', 'post', 'mid'}}#{|Literal['pre', 'post', 'mid'}]
1#array-like or PIL image#array-like|PIL image
1#{'equal', 'auto'} or float#float|Literal['equal', 'auto']
1#{'data', 'rgba'}#Literal['data', 'rgba']
1#floats (left, right, bottom, top)#floats|tuple[left, right, bottom, top]
1#float > 0#float > 0
1#{'flat', 'nearest', 'auto'}#Literal['flat', 'nearest', 'auto']
1#`matplotlib.collections.Collection`#matplotlib.collections.Collection
1#{'flat', 'nearest', 'gouraud', 'auto'}#Literal['flat', 'nearest', 'gouraud', 'auto']
1#`matplotlib.collections.QuadMesh`#matplotlib.collections.QuadMesh
1#`.AxesImage` or `.PcolorImage` or `.QuadMesh`#AxesImage|PcolorImage|QuadMesh
1#`.ContourSet` instance#ContourSet instance
1#(n,) array or sequence of (n,) arrays#(n|) array|sequence of  arrays|tuple[n,]
1#int or sequence or str#int|sequence|str
1#tuple or None#tuple|None
1#(n,) array-like or None#array-like|None|tuple[n,]
1#bool or -1#bool|Literal[-1]
1#array-like, scalar, or None#array-like|scalar|None
1#{'bar', 'barstacked', 'step', 'stepfilled'}#Literal['bar', 'barstacked', 'step', 'stepfilled']
1#{'left', 'mid', 'right'}#Literal['left', 'mid', 'right']
1#color or array-like of colors or None#color|array-like of colors|None
1#array or list of arrays#array|Sequence[arrays]
1#array#array
1#`.BarContainer` or list of a single `.Polygon` or list of such objects#BarContainer|list of a single .Polygon|list of such objects
1#float, array-like or None#float|array-like|None
1#`matplotlib.patches.StepPatch`#matplotlib.patches.StepPatch
1#None or int or [int, int] or array-like or [array, array]#None|int|[int|int]|array-like|tuple[array, array]
1#array-like shape(2, 2)#array-like shape|tuple[2, 2]
1#`~.matplotlib.collections.QuadMesh`#matplotlib.collections.QuadMesh
1#{'default', 'psd', 'magnitude', 'angle', 'phase'}#Literal['default', 'psd', 'magnitude', 'angle', 'phase']
1#`.Colormap`#Colormap
1#*None* or (xmin, xmax)#*None*|tuple[xmin, xmax]
1#`.AxesImage`#AxesImage
1#float or 'present'#float|Literal['present']
1#{'equal', 'auto', None} or float#float|Literal['equal', 'auto', None]
1#`~matplotlib.image.AxesImage` or `.Line2D`#matplotlib.image.AxesImage|Line2D
1#str, scalar or callable#str|scalar|callable
1#tuple#tuple
1#result#result
1#`~matplotlib.figure.Figure`#matplotlib.figure.Figure
1#[left, bottom, width, height]#tuple[left, bottom, width, height]
1#`.Figure`#Figure
1#[left, bottom, width, height] or `~matplotlib.transforms.Bbox`#matplotlib.transforms.Bbox|tuple[left, bottom, width, height]
1#{'both', 'active', 'original'}#Literal['both', 'active', 'original']
1#Callable[[Axes, Renderer], Bbox]#Callable[|tuple[Axes, Renderer], Bbox]
1#Patch#Patch
1#Cycler#Cycler
1#iterable#iterable
1#{'auto', 'equal'} or float#float|Literal['auto', 'equal']
1#None or {'box', 'datalim'}#None|Literal['box', 'datalim']
1#None or str or (float, float)#None|str|tuple[float, float]
1#{'box', 'datalim'}#Literal['box', 'datalim']
1#(float, float) or {'C', 'SW', 'S', 'SE', 'E', 'NE', ...}#Literal['C', 'SW', 'S', 'SE', 'E', 'NE', ...]|tuple[float, float]
1#bool or str#bool|str
1#`.RendererBase` subclass.#RendererBase subclass.
1#`.Line2D` properties#Line2D properties
1#{'sci', 'scientific', 'plain'}#Literal['sci', 'scientific', 'plain']
1#pair of ints (m, n)#pair of ints|tuple[m, n]
1#bool or float#bool|float
1#{'left', 'center', 'right'}#Literal['left', 'center', 'right']
1#The limit value after call to convert(), or None if limit is None.#The limit value after call to convert|None if limit is None.|tuple[]
1#{'bottom', 'center', 'top'}#Literal['bottom', 'center', 'top']
1#4-tuple or 3 tuple#4-tuple|3 tuple
1#`matplotlib.backend_bases.MouseEvent`#matplotlib.backend_bases.MouseEvent
1#`.RendererBase` subclass#RendererBase subclass
1#list of `.Artist` or ``None``#Sequence[Artist]|None
1#default: False#default: False
1#`.BboxBase`#BboxBase
1#`matplotlib.figure.Figure`#matplotlib.figure.Figure
1#tuple (*nrows*, *ncols*, *index*) or int#tuple|int|tuple[*nrows*, *ncols*, *index*]
1#list of floats#Sequence[floats]
1#2-tuple of func, or `Transform` with an inverse.#2-tuple of func|Transform with an inverse.
```

Our crude normalizer hasn't done too badly; the bulk of these types make sense and many of them are usable as is. Others are clear enough that we could easily come up with an alternative to map them to.

There's definitely some near the end of the list where we are messing up; I'll look at those in more detail later and see how we can tweak normalization. A typical cause is when my current limitation of only being able to handle one literal or tuple in a type description is violated, either by multiple of these on a line or cases where they may be nested.

Nonetheless, you can see that there are only a little over 200 lines in this map file; considering how long it would take to hand-correct all the types individually and turn them into annotations, versus editing this file and automatically inserting them, this approach should pay off.

## Next Time

That's enough for one day; in subsequent posts I will look at:

- improving the normalization; there's some easy low-hanging fruit that can be addressed with little risk
- collecting a mapping for a whole package at a time instead of a single module
- maintaining persistent map files, a general and ones that are package-specific. For example, something like `float` would go in the general mapping file, while `list[Line2D]` would go in a `matplotlib` mapping file. Once we have these, we can check if a type already exists in the general mapping file, or the one for that package, and if so, we can omit it from the output. Then we only have to update what is left. This will make it easier to maintain stubs when new versions of a package are released.
- applying the types in the various mapping files to our stubs.






