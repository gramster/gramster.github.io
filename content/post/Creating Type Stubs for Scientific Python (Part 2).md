# Creating Type Stubs for Scientific Python (Part 2)

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

## The Analyzer

### Parsing the Docstrings

As I mentioned, I wrote a parser for matplotlib, and while I could use it, its not the cleanest code. And once I learned about numpydoc, Michael Droettboom, the creator of matplotlib and a member of my team, pointed out to me that there is a sphinx extension called "napoleon" that [parses these docstrings](https://github.com/sphinx-doc/sphinx/blob/5.x/sphinx/ext/napoleon/docstring.py). So I am going to do like all great artists and steal in the code below. An advantage of going this route is that napoleon also supports Google docstring format, so I can easily extend the parser later for that if I choose.

One of the things I want to do is 'normalize' the types after I extract them. For example, I want to drop the 'Optional...' part if it exists, because it adds no value if you have the default values in function and method signatures. But because the normalization process is dealing with imperfect data, I want to retain the original text as well, so if I get strange results from normalization I can refer back to the original text. For now I will just add an identity function that does nothing for the normalizer.

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
                       ) -> tuple[str, str, str]: ...

    def _consume_fields(self, parse_type: bool = True, prefer_type: bool = False,
                        multiple: bool = False) -> list[tuple[str, str, str]]:
        self._consume_empty()
        fields = []
        while not self._is_section_break():
            name, raw, normalized = self._consume_field(prefer_type)
            if multiple and name:
                for n in name.split(","):
                    fields.append((n.strip(), raw, normalized))
            elif name or normalized:
                fields.append((name, raw, normalized))
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

    @staticmethod
    def _normalize(s: str) -> str:
        return s

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
                       ) -> tuple[str, str, str]:
        line = self._lines.next()
        
        _name, _, _type = self._partition_field_on_colon(line)
        _name, _type = _name.strip(), _type.strip()

        if prefer_type and not _type:
            _type, _name = _name, _type

        # Consume the description
        self._consume_indented_block(self._get_indent(line) + 1)
        return _name, _type, NumpyDocstringParser._normalize(_type)

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
  name prop: type {"colors", "sizes"}, default: "colors"
  name num: type int, None, "auto" (default), array-like, or `~.ticker.Locator`
  name fmt: type str, `~matplotlib.ticker.Formatter`, or None (default)
  name func: type function, default: ``lambda x: x``
  name **kwargs: type 
Returns
-------
  name handles: type list of `.Line2D`
  name labels: type list of str
```

Of course, this has just got the raw fields out of the docstring; there's no normalization or conversion to something closer to Python type annotations yet. In the next section we will work on addressing that.

### Best-Effort Type Cleaning

Let's first focus on our test case.

The first thing we can do is throw away anything that starts with ", default ...", as we will get the default from the definition itself. For the `num` parameter, the default was specified differently, by annotating one of the options with "(default)", so we can erase that string too. We then are left with comma-separated strings (where the last element is separated by "or" instead). However, we have the constrained parameter `prop` that has a list of possible values, and these are comma separated too. Plus some types may be tuples, enclosed in parentheses. So we should start with such compound types and then after that we can turn the lists of types into unions. At least in matplotlib, some types start with '.' (meaning they are classes defined in the same file, I believe); we can strip those off. And while we're at it, some start with '~', which seems redundant too (I'm not sure what it is supposed to denote; I'll try find out). Let's update the static method `_normalize` to `NumpyDocstringParser` to do all this:

```python
    remove_default_val = re.compile(r'^(.*),[ \t]*default[ \t]*.*$')
    restricted_val = re.compile(r'^(.*){(.*)}(.*)$')
    _tuple1 = re.compile(r'^(.*)\((.*)\)(.*)$')  # using ()
    _tuple2 = re.compile(r'^(.*)\[(.*)\](.*)$')  # using []    
    @staticmethod
    def _normalize(s: str) -> str:
        # Remove , default ... from end
        m = NumpyDocstringParser._remove_default_val.match(s)
        if m:
            s = m.group(1)
        # Remove (default) from within
        s = s.replace('(default)', '')
        # Handle a restricted value set
        m = NumpyDocstringParser._restricted_val.match(s)
        l = None
        if m:
            s = m.group(1) + m.group(3)
            l = 'Literal[' + m.group(2) + ']'

        # Handle tuples. Right now we can only handle one per line;
        # need to fix that.

        m = NumpyDocstringParser._tuple1.match(s)
        if not m:
            m = NumpyDocstringParser._tuple2.match(s)
        t = None
        if m:
            s = m.group(1) + m.group(3)
            t = 'tuple(' + m.group(2) + ')'

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

            # Handle literal numbers and strings
            if not (s.startswith('"') or s.startswith("'")):
                try:
                    float(s)
                except ValueError:
                    # Handle lists
                    if s.startswith('list of '):
                        s = s[8:]
                        if s.startswith('.') or s.startswith('~'):
                            s = s[1:]
                        return 'list[' + s + ']'
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

It's not a thing of beauty at all, and I'm not proud of it, but it's a good start for us to explore in more detail what other cases there might be. With a one line change to the print statement in our test runner, we can see the new output:

```
Params
------
  name prop: raw {"colors", "sizes"}, default: "colors", normalized Literal["colors", "sizes"]
  name num: raw int, None, "auto" (default), array-like, or `~.ticker.Locator`, normalized int|None|Literal["auto"]|array-like|ticker.Locator
  name fmt: raw str, `~matplotlib.ticker.Formatter`, or None (default), normalized str|matplotlib.ticker.Formatter|None
  name func: raw function, default: ``lambda x: x``, normalized function
  name **kwargs: raw , normalized 
Returns
-------
  name handles: raw list of `.Line2D`, normalized list[Line2D]
  name labels: raw list of str, normalized list[str]
```

In order to figure out how best to proceed from here, its time to gather more data than we got from just our simple example.

### Writing the Map File

For the map file, we are going to import a module, look at all of the docstrings, pull out the normalized types, split them on '|' if they are unions, and add them to a set where we also maintain counts. We can then output this in order of frequency. This will quickly give us much more data to look at to see what we are dealing with.

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

```python
from ast import Num
from collections import Counter
import inspect
from types import ModuleType
import libcst as cst
from .basetransformer import BaseTransformer
from .utils import process_module
from .parser import NumpyDocstringParser


class AnalyzingTransformer(BaseTransformer):

    def __init__(self, mod: ModuleType, fname: str, counter: Counter, context: dict):
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
        self._context = context

    def _analyze_obj(self, obj, context: str):
        doc = None
        if obj:
            doc = inspect.getdoc(obj)
        if not doc:
            return
        rtn = self._parser.parse(doc)
        for section in rtn:
            if section:
                for _, raw, typs in section:
                    for typ in typs.split('|'):
                        if typ not in self._context:
                            self._context[typ] = f'{self._fname}:{context} {raw}'
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
        patcher = AnalyzingTransformer(mod, fname, counter=state[0], context=state[1])
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
    context: dict = state[1]
    for typ, cnt in freq.most_common():
        result += f'{cnt}#{context[typ]}#{typ}#{typ}\n'
    return result


def _targeter(m: str) -> str:
    """ Turn module name into map file name """
    return f"analysis/{m}.typ"


def analyze_module(m: str):
    process_module(m, _analyze, _targeter, post_processor=_post_process, 
        state=(Counter(), {}))

```

## Testing the Analysis

We can now run this on a module. Below is the output from analyzing `matplotlib.axes`. Each line is a count followed by the type. The type appears twice because this is a mapping file; later we will have the opportunity to edit this file to remap the types before they get injected.

```
149#matplotlib/axes/_axes.py:Axes.set_title float, default: :rc:`axes.titley`#float#float
125#matplotlib/axes/_axes.py:Axes.legend sequence of `.Artist`, optional#optional#optional
109#matplotlib/axes/_axes.py:Axes.annotate bool or None, default: None#bool#bool
84#matplotlib/axes/_axes.py:Axes.hlines float or array-like#array-like#array-like
42#matplotlib/axes/_axes.py:Axes.get_title {'center', 'left', 'right'}, str, default: 'center'#str#str
37#matplotlib/axes/_axes.py:Axes.annotate bool or None, default: None#None#None
35#matplotlib/axes/_axes.py:Axes.acorr int, default: 10#int#int
23#matplotlib/axes/_axes.py:Axes.set_title dict#dict#dict
19#matplotlib/axes/_axes.py:Axes.inset_axes ##
19#matplotlib/axes/_axes.py:Axes.psd 1-D array or sequence#1-D array#1-D array
18#matplotlib/axes/_axes.py:Axes.annotate str or `.Artist` or `.Transform` or callable or (float, float), default: 'data'#callable#callable
16#matplotlib/axes/_axes.py:Axes.indicate_inset color, default: 'none'#color#color
16#matplotlib/axes/_axes.py:Axes.acorr array (length ``2*maxlags+1``)#array#array
14#matplotlib/axes/_axes.py:Axes.annotate (float, float)#tuple(float, float)#tuple(float, float)
13#matplotlib/axes/_axes.py:Axes.quiver 1D or 2D array-like, optional#2D array-like#2D array-like
12#matplotlib/axes/_axes.py:Axes._fill_between_x_or_y array (length N)#tuple(length N)#tuple(length N)
10#matplotlib/axes/_axes.py:Axes.plot array-like or scalar#scalar#scalar
10#matplotlib/axes/_axes.py:Axes.loglog sequence, optional#sequence#sequence
10#matplotlib/axes/_axes.py:Axes.quiver 1D or 2D array-like, optional#1D#1D
8#matplotlib/axes/_axes.py:Axes.inset_axes `.Transform`#Transform#Transform
8#matplotlib/axes/_axes.py:Axes.eventplot indexable object, optional#indexable object#indexable object
8#matplotlib/axes/_axes.py:Axes.errorbar float or array-like, shape(N,) or shape(2, N), optional#shape#shape
7#matplotlib/axes/_axes.py:Axes.axhline `~matplotlib.lines.Line2D`#matplotlib.lines.Line2D#matplotlib.lines.Line2D
7#matplotlib/axes/_axes.py:Axes.psd callable or ndarray, default: `.window_hanning`#ndarray#ndarray
7#matplotlib/axes/_axes.py:Axes.psd {'default', 'onesided', 'twosided'}, optional#Literal['default', 'onesided', 'twosided']#Literal['default', 'onesided', 'twosided']
6#matplotlib/axes/_axes.py:Axes.get_title {'center', 'left', 'right'}, str, default: 'center'#Literal['center', 'left', 'right']#Literal['center', 'left', 'right']
6#matplotlib/axes/_axes.py:Axes.axline `.Line2D`#Line2D#Line2D
6#matplotlib/axes/_axes.py:Axes.eventplot str or tuple or list of such values, default: 'solid'#tuple#tuple
6#matplotlib/axes/_axes.py:Axes.plot list of `.Line2D`#list[Line2D]#list[Line2D]
6#matplotlib/axes/_axes.py:Axes.pie list, default: None#list#list
6#matplotlib/axes/_axes.py:Axes.scatter float or array-like, shape (n, )#tuple(n, )#tuple(n, )
5#matplotlib/axes/_axes.py:Axes.scatter str or `~matplotlib.colors.Colormap`, default: :rc:`image.cmap`#matplotlib.colors.Colormap#matplotlib.colors.Colormap
5#matplotlib/axes/_axes.py:Axes.scatter `~matplotlib.colors.Normalize`, default: None#matplotlib.colors.Normalize#matplotlib.colors.Normalize
4#matplotlib/axes/_axes.py:Axes.indicate_inset `.Axes`#Axes#Axes
4#matplotlib/axes/_axes.py:Axes.hlines list of colors, default: :rc:`lines.color`#list[colors]#list[colors]
4#matplotlib/axes/_axes.py:Axes.acorr array (length ``2*maxlags+1``)#tuple(length ``2*maxlags+1``)#tuple(length ``2*maxlags+1``)
4#matplotlib/axes/_axes.py:Axes.bar `.BarContainer`#BarContainer#BarContainer
4#matplotlib/axes/_axes.py:Axes.contour (M, N) array-like#tuple(M, N)#tuple(M, N)
4#matplotlib/axes/_axes.py:Axes.psd {'none', 'mean', 'linear'} or callable, default: 'none'#Literal['none', 'mean', 'linear']#Literal['none', 'mean', 'linear']
4#matplotlib/axes/_base.py:_AxesBase.get_xaxis_text1_transform {'center', 'top', 'bottom', 'baseline', 'center_baseline'}#Literal['center', 'top', 'bottom', 'baseline', 'center_baseline']#Literal['center', 'top', 'bottom', 'baseline', 'center_baseline']
3#matplotlib/axes/_axes.py:Axes `.Bbox`#Bbox#Bbox
3#matplotlib/axes/_axes.py:Axes.secondary_xaxis {'top', 'bottom', 'left', 'right'} or float#Literal['top', 'bottom', 'left', 'right']#Literal['top', 'bottom', 'left', 'right']
3#matplotlib/axes/_axes.py:Axes.secondary_xaxis 2-tuple of func, or Transform with an inverse#2-tuple of func#2-tuple of func
3#matplotlib/axes/_axes.py:Axes.loglog {'mask', 'clip'}, default: 'mask'#Literal['mask', 'clip']#Literal['mask', 'clip']
3#matplotlib/axes/_axes.py:Axes.step {'pre', 'post', 'mid'}, default: 'pre'#Literal['pre', 'post', 'mid']#Literal['pre', 'post', 'mid']
3#matplotlib/axes/_axes.py:Axes._parse_scatter_color_args color or sequence or sequence of color or None#sequence of color#sequence of color
3#matplotlib/axes/_axes.py:Axes.quiver color or color sequence, optional#color sequence#color sequence
3#matplotlib/axes/_axes.py:Axes._fill_between_x_or_y array of bool (length N), optional#array of bool#array of bool
3#matplotlib/axes/_axes.py:Axes._fill_between_x_or_y `.PolyCollection`#PolyCollection#PolyCollection
3#matplotlib/axes/_axes.py:Axes.imshow `~matplotlib.image.AxesImage`#matplotlib.image.AxesImage#matplotlib.image.AxesImage
3#matplotlib/axes/_base.py:_AxesBase.__init__ `~.axes.Axes`, optional#axes.Axes#axes.Axes
3#matplotlib/axes/_base.py:_AxesBase.autoscale {'both', 'x', 'y'}, default: 'both'#Literal['both', 'x', 'y']#Literal['both', 'x', 'y']
2#matplotlib/axes/_axes.py:Axes.set_title `.Text`#Text#Text
2#matplotlib/axes/_axes.py:Axes.legend list of str, optional#list[str]#list[str]
2#matplotlib/axes/_axes.py:Axes.inset_axes [x0, y0, width, height]#tuple(x0, y0, width, height)#tuple(x0, y0, width, height)
2#matplotlib/axes/_axes.py:Axes.indicate_inset `.patches.Rectangle`#patches.Rectangle#patches.Rectangle
2#matplotlib/axes/_axes.py:Axes.indicate_inset 4-tuple of `.patches.ConnectionPatch`#4-tuple of .patches.ConnectionPatch#4-tuple of .patches.ConnectionPatch
2#matplotlib/axes/_axes.py:Axes.secondary_xaxis 2-tuple of func, or Transform with an inverse#Transform with an inverse#Transform with an inverse
2#matplotlib/axes/_axes.py:Axes.secondary_xaxis axes._secondary_axes.SecondaryAxis#axes._secondary_axes.SecondaryAxis#axes._secondary_axes.SecondaryAxis
2#matplotlib/axes/_axes.py:Axes.annotate str or `.Artist` or `.Transform` or callable or (float, float), default: 'data'#Artist#Artist
2#matplotlib/axes/_axes.py:Axes.axhspan `~matplotlib.patches.Polygon`#matplotlib.patches.Polygon#matplotlib.patches.Polygon
2#matplotlib/axes/_axes.py:Axes.hlines {'solid', 'dashed', 'dashdot', 'dotted'}, optional#Literal['solid', 'dashed', 'dashdot', 'dotted']#Literal['solid', 'dashed', 'dashdot', 'dotted']
2#matplotlib/axes/_axes.py:Axes.hlines `~matplotlib.collections.LineCollection`#matplotlib.collections.LineCollection#matplotlib.collections.LineCollection
2#matplotlib/axes/_axes.py:Axes.acorr `.LineCollection` or `.Line2D`#LineCollection#LineCollection
2#matplotlib/axes/_axes.py:Axes.xcorr array-like of length n#array-like of length n#array-like of length n
2#matplotlib/axes/_axes.py:Axes.bar {'center', 'edge'}, default: 'center'#Literal['center', 'edge']#Literal['center', 'edge']
2#matplotlib/axes/_axes.py:Axes.pie 1D array-like#1D array-like#1D array-like
2#matplotlib/axes/_axes.py:Axes.errorbar float or array-like, shape(N,) or shape(2, N), optional#shape(N#shape(N
2#matplotlib/axes/_axes.py:Axes.errorbar float or array-like, shape(N,) or shape(2, N), optional#)#)
2#matplotlib/axes/_axes.py:Axes.errorbar float or array-like, shape(N,) or shape(2, N), optional#tuple(2, N)#tuple(2, N)
2#matplotlib/axes/_axes.py:Axes.errorbar int or (int, int), default: 1#tuple(int, int)#tuple(int, int)
2#matplotlib/axes/_axes.py:Axes.boxplot Array or a sequence of vectors.#Array#Array
2#matplotlib/axes/_axes.py:Axes.boxplot Array or a sequence of vectors.#a sequence of vectors.#a sequence of vectors.
2#matplotlib/axes/_axes.py:Axes.bxp list of dicts#list[dicts]#list[dicts]
2#matplotlib/axes/_axes.py:Axes.hexbin {'linear', 'log'}, default: 'linear'#Literal['linear', 'log']#Literal['linear', 'log']
2#matplotlib/axes/_axes.py:Axes.quiverkey `matplotlib.quiver.Quiver`#matplotlib.quiver.Quiver#matplotlib.quiver.Quiver
2#matplotlib/axes/_axes.py:Axes.quiver {'width', 'height', 'dots', 'inches', 'x', 'y', 'xy'}, default: 'width'#Literal['width', 'height', 'dots', 'inches', 'x', 'y', 'xy']#Literal['width', 'height', 'dots', 'inches', 'x', 'y', 'xy']
2#matplotlib/axes/_axes.py:Axes.imshow {'upper', 'lower'}, default: :rc:`image.origin`#Literal['upper', 'lower']#Literal['upper', 'lower']
2#matplotlib/axes/_axes.py:Axes.pcolor {'none', None, 'face', color, color sequence}, optional#Literal['none', None, 'face', color, color sequence]#Literal['none', None, 'face', color, color sequence]
2#matplotlib/axes/_axes.py:Axes.pcolormesh `matplotlib.collections.QuadMesh`#matplotlib.collections.QuadMesh#matplotlib.collections.QuadMesh
2#matplotlib/axes/_axes.py:Axes.pcolorfast `.AxesImage` or `.PcolorImage` or `.QuadMesh`#AxesImage#AxesImage
2#matplotlib/axes/_axes.py:Axes.contour `~.contour.QuadContourSet`#contour.QuadContourSet#contour.QuadContourSet
2#matplotlib/axes/_axes.py:Axes.hist (n,) array or sequence of (n,) arrays#tuple(n,)#tuple(n,)
2#matplotlib/axes/_axes.py:Axes.hist {'vertical', 'horizontal'}, default: 'vertical'#Literal['vertical', 'horizontal']#Literal['vertical', 'horizontal']
2#matplotlib/axes/_axes.py:Axes.hist2d 2D array#2D array#2D array
2#matplotlib/axes/_axes.py:Axes.hist2d 1D array#1D array#1D array
2#matplotlib/axes/_axes.py:Axes.csd 1-D arrays or sequences#1-D arrays#1-D arrays
2#matplotlib/axes/_axes.py:Axes.csd 1-D arrays or sequences#sequences#sequences
2#matplotlib/axes/_axes.py:Axes.magnitude_spectrum {'default', 'linear', 'dB'}#Literal['default', 'linear', 'dB']#Literal['default', 'linear', 'dB']
2#matplotlib/axes/_base.py:_AxesBase.__init__ `~matplotlib.figure.Figure`#matplotlib.figure.Figure#matplotlib.figure.Figure
2#matplotlib/axes/_base.py:_AxesBase.__init__ [left, bottom, width, height]#tuple(left, bottom, width, height)#tuple(left, bottom, width, height)
2#matplotlib/axes/_base.py:_AxesBase.set_aspect None or {'box', 'datalim'}, optional#Literal['box', 'datalim']#Literal['box', 'datalim']
2#matplotlib/axes/_base.py:_AxesBase.set_xmargin float greater than -0.5#float greater than -0.5#float greater than -0.5
2#matplotlib/axes/_base.py:_AxesBase.get_axisbelow bool or 'line'#Literal['line']#Literal['line']
2#matplotlib/axes/_base.py:_AxesBase.grid {'major', 'minor', 'both'}, optional#Literal['major', 'minor', 'both']#Literal['major', 'minor', 'both']
2#matplotlib/axes/_base.py:_AxesBase.ticklabel_format {'x', 'y', 'both'}, default: 'both'#Literal['x', 'y', 'both']#Literal['x', 'y', 'both']
2#matplotlib/axes/_base.py:_AxesBase.set_xscale {"linear", "log", "symlog", "logit", ...} or `.ScaleBase`#ScaleBase#ScaleBase
2#matplotlib/axes/_base.py:_AxesBase.set_xscale {"linear", "log", "symlog", "logit", ...} or `.ScaleBase`#Literal["linear", "log", "symlog", "logit", ...]#Literal["linear", "log", "symlog", "logit", ...]
2#matplotlib/axes/_base.py:_AxesBase.start_pan `.MouseButton`#MouseButton#MouseButton
1#matplotlib/axes/_axes.py:Axes.legend sequence of `.Artist`, optional#sequence of .Artist#sequence of .Artist
1#matplotlib/axes/_axes.py:Axes.legend `~matplotlib.legend.Legend`#matplotlib.legend.Legend#matplotlib.legend.Legend
1#matplotlib/axes/_axes.py:Axes.inset_axes number#number#number
1#matplotlib/axes/_axes.py:Axes.inset_axes ax#ax#ax
1#matplotlib/axes/_axes.py:Axes.annotate `.Annotation`#Annotation#Annotation
1#matplotlib/axes/_axes.py:Axes.eventplot array-like or list of array-like#list[array-like]#list[array-like]
1#matplotlib/axes/_axes.py:Axes.eventplot {'horizontal', 'vertical'}, default: 'horizontal'#Literal['horizontal', 'vertical']#Literal['horizontal', 'vertical']
1#matplotlib/axes/_axes.py:Axes.eventplot str or tuple or list of such values, default: 'solid'#list[such values]#list[such values]
1#matplotlib/axes/_axes.py:Axes.eventplot list of `.EventCollection`#list[EventCollection]#list[EventCollection]
1#matplotlib/axes/_axes.py:Axes.plot_date timezone string or `datetime.tzinfo`, default: :rc:`timezone`#timezone string#timezone string
1#matplotlib/axes/_axes.py:Axes.plot_date timezone string or `datetime.tzinfo`, default: :rc:`timezone`#datetime.tzinfo#datetime.tzinfo
1#matplotlib/axes/_axes.py:Axes.bar_label {'edge', 'center'}, default: 'edge'#Literal['edge', 'center']#Literal['edge', 'center']
1#matplotlib/axes/_axes.py:Axes.bar_label list of `.Text`#list[Text]#list[Text]
1#matplotlib/axes/_axes.py:Axes.broken_barh sequence of tuples (*xmin*, *xwidth*)#sequence of tuples#sequence of tuples
1#matplotlib/axes/_axes.py:Axes.broken_barh sequence of tuples (*xmin*, *xwidth*)#tuple(*xmin*, *xwidth*)#tuple(*xmin*, *xwidth*)
1#matplotlib/axes/_axes.py:Axes.broken_barh (*ymin*, *yheight*)#tuple(*ymin*, *yheight*)#tuple(*ymin*, *yheight*)
1#matplotlib/axes/_axes.py:Axes.broken_barh `~.collections.BrokenBarHCollection`#collections.BrokenBarHCollection#collections.BrokenBarHCollection
1#matplotlib/axes/_axes.py:Axes.stem `.StemContainer`#StemContainer#StemContainer
1#matplotlib/axes/_axes.py:Axes.errorbar `.ErrorbarContainer`#ErrorbarContainer#ErrorbarContainer
1#matplotlib/axes/_axes.py:Axes._parse_scatter_color_args color or sequence of color or {'face', 'none'} or None#Literal['face', 'none']#Literal['face', 'none']
1#matplotlib/axes/_axes.py:Axes._parse_scatter_color_args c#c#c
1#matplotlib/axes/_axes.py:Axes._parse_scatter_color_args array(N, 4) or None#tuple(N, 4)#tuple(N, 4)
1#matplotlib/axes/_axes.py:Axes._parse_scatter_color_args edgecolors#edgecolors#edgecolors
1#matplotlib/axes/_axes.py:Axes.scatter `~.markers.MarkerStyle`, default: :rc:`scatter.marker`#markers.MarkerStyle#markers.MarkerStyle
1#matplotlib/axes/_axes.py:Axes.scatter {'face', 'none', *None*} or color or sequence of color, default: :rc:`scatter.edgecolors`#Literal['face', 'none', *None*]#Literal['face', 'none', *None*]
1#matplotlib/axes/_axes.py:Axes.scatter `~matplotlib.collections.PathCollection`#matplotlib.collections.PathCollection#matplotlib.collections.PathCollection
1#matplotlib/axes/_axes.py:Axes.hexbin 'log' or int or sequence, default: None#Literal['log']#Literal['log']
1#matplotlib/axes/_axes.py:Axes.hexbin int > 0, default: *None*#int > 0#int > 0
1#matplotlib/axes/_axes.py:Axes.hexbin 4-tuple of float, default: *None*#4-tuple of float#4-tuple of float
1#matplotlib/axes/_axes.py:Axes.hexbin `~matplotlib.collections.PolyCollection`#matplotlib.collections.PolyCollection#matplotlib.collections.PolyCollection
1#matplotlib/axes/_axes.py:Axes.arrow {'full', 'left', 'right'}, default: 'full'#Literal['full', 'left', 'right']#Literal['full', 'left', 'right']
1#matplotlib/axes/_axes.py:Axes.arrow `.FancyArrow`#FancyArrow#FancyArrow
1#matplotlib/axes/_axes.py:Axes.quiverkey {'axes', 'figure', 'data', 'inches'}, default: 'axes'#Literal['axes', 'figure', 'data', 'inches']#Literal['axes', 'figure', 'data', 'inches']
1#matplotlib/axes/_axes.py:Axes.quiverkey {'N', 'S', 'E', 'W'}#Literal['N', 'S', 'E', 'W']#Literal['N', 'S', 'E', 'W']
1#matplotlib/axes/_axes.py:Axes.quiver {'uv', 'xy'} or array-like, default: 'uv'#Literal['uv', 'xy']#Literal['uv', 'xy']
1#matplotlib/axes/_axes.py:Axes.quiver {'tail', 'mid', 'middle', 'tip'}, default: 'tail'#Literal['tail', 'mid', 'middle', 'tip']#Literal['tail', 'mid', 'middle', 'tip']
1#matplotlib/axes/_axes.py:Axes.barbs {'tip', 'middle'} or float, default: 'tip'#Literal['tip', 'middle']#Literal['tip', 'middle']
1#matplotlib/axes/_axes.py:Axes.barbs bool or array-like of bool, default: False#array-like of bool#array-like of bool
1#matplotlib/axes/_axes.py:Axes.barbs `~matplotlib.quiver.Barbs`#matplotlib.quiver.Barbs#matplotlib.quiver.Barbs
1#matplotlib/axes/_axes.py:Axes.fill sequence of x, y, [color]#sequence of x#sequence of x
1#matplotlib/axes/_axes.py:Axes.fill sequence of x, y, [color]#y#y
1#matplotlib/axes/_axes.py:Axes.fill sequence of x, y, [color]#tuple(color)#tuple(color)
1#matplotlib/axes/_axes.py:Axes.fill list of `~matplotlib.patches.Polygon`#list[matplotlib.patches.Polygon]#list[matplotlib.patches.Polygon]
1#matplotlib/axes/_axes.py:Axes._fill_between_x_or_y {{'pre', 'post', 'mid'}}, optional#{#{
1#matplotlib/axes/_axes.py:Axes._fill_between_x_or_y {{'pre', 'post', 'mid'}}, optional#Literal['pre', 'post', 'mid'}]#Literal['pre', 'post', 'mid'}]
1#matplotlib/axes/_axes.py:Axes.imshow array-like or PIL image#PIL image#PIL image
1#matplotlib/axes/_axes.py:Axes.imshow {'equal', 'auto'} or float, default: :rc:`image.aspect`#Literal['equal', 'auto']#Literal['equal', 'auto']
1#matplotlib/axes/_axes.py:Axes.imshow {'data', 'rgba'}, default: 'data'#Literal['data', 'rgba']#Literal['data', 'rgba']
1#matplotlib/axes/_axes.py:Axes.imshow floats (left, right, bottom, top), optional#floats#floats
1#matplotlib/axes/_axes.py:Axes.imshow floats (left, right, bottom, top), optional#tuple(left, right, bottom, top)#tuple(left, right, bottom, top)
1#matplotlib/axes/_axes.py:Axes.imshow float > 0, default: 4.0#float > 0#float > 0
1#matplotlib/axes/_axes.py:Axes.pcolor {'flat', 'nearest', 'auto'}, default: :rc:`pcolor.shading`#Literal['flat', 'nearest', 'auto']#Literal['flat', 'nearest', 'auto']
1#matplotlib/axes/_axes.py:Axes.pcolor `matplotlib.collections.Collection`#matplotlib.collections.Collection#matplotlib.collections.Collection
1#matplotlib/axes/_axes.py:Axes.pcolormesh {'flat', 'nearest', 'gouraud', 'auto'}, optional#Literal['flat', 'nearest', 'gouraud', 'auto']#Literal['flat', 'nearest', 'gouraud', 'auto']
1#matplotlib/axes/_axes.py:Axes.pcolorfast `.AxesImage` or `.PcolorImage` or `.QuadMesh`#PcolorImage#PcolorImage
1#matplotlib/axes/_axes.py:Axes.pcolorfast `.AxesImage` or `.PcolorImage` or `.QuadMesh`#QuadMesh#QuadMesh
1#matplotlib/axes/_axes.py:Axes.clabel `.ContourSet` instance#ContourSet instance#ContourSet instance
1#matplotlib/axes/_axes.py:Axes.hist (n,) array or sequence of (n,) arrays#(n#(n
1#matplotlib/axes/_axes.py:Axes.hist (n,) array or sequence of (n,) arrays#) array#) array
1#matplotlib/axes/_axes.py:Axes.hist (n,) array or sequence of (n,) arrays#sequence of  arrays#sequence of  arrays
1#matplotlib/axes/_axes.py:Axes.hist bool or -1, default: False#Literal[-1]#Literal[-1]
1#matplotlib/axes/_axes.py:Axes.hist {'bar', 'barstacked', 'step', 'stepfilled'}, default: 'bar'#Literal['bar', 'barstacked', 'step', 'stepfilled']#Literal['bar', 'barstacked', 'step', 'stepfilled']
1#matplotlib/axes/_axes.py:Axes.hist {'left', 'mid', 'right'}, default: 'mid'#Literal['left', 'mid', 'right']#Literal['left', 'mid', 'right']
1#matplotlib/axes/_axes.py:Axes.hist color or array-like of colors or None, default: None#array-like of colors#array-like of colors
1#matplotlib/axes/_axes.py:Axes.hist array or list of arrays#list[arrays]#list[arrays]
1#matplotlib/axes/_axes.py:Axes.hist `.BarContainer` or list of a single `.Polygon` or list of such objects#list[a single .Polygon]#list[a single .Polygon]
1#matplotlib/axes/_axes.py:Axes.hist `.BarContainer` or list of a single `.Polygon` or list of such objects#list[such objects]#list[such objects]
1#matplotlib/axes/_axes.py:Axes.stairs `matplotlib.patches.StepPatch`#matplotlib.patches.StepPatch#matplotlib.patches.StepPatch
1#matplotlib/axes/_axes.py:Axes.hist2d None or int or [int, int] or array-like or [array, array]#[int#[int
1#matplotlib/axes/_axes.py:Axes.hist2d None or int or [int, int] or array-like or [array, array]#int]#int]
1#matplotlib/axes/_axes.py:Axes.hist2d None or int or [int, int] or array-like or [array, array]#tuple(array, array)#tuple(array, array)
1#matplotlib/axes/_axes.py:Axes.hist2d array-like shape(2, 2), optional#array-like shape#array-like shape
1#matplotlib/axes/_axes.py:Axes.hist2d array-like shape(2, 2), optional#tuple(2, 2)#tuple(2, 2)
1#matplotlib/axes/_axes.py:Axes.specgram {'default', 'psd', 'magnitude', 'angle', 'phase'}#Literal['default', 'psd', 'magnitude', 'angle', 'phase']#Literal['default', 'psd', 'magnitude', 'angle', 'phase']
1#matplotlib/axes/_axes.py:Axes.specgram `.Colormap`, default: :rc:`image.cmap`#Colormap#Colormap
1#matplotlib/axes/_axes.py:Axes.specgram *None* or (xmin, xmax)#*None*#*None*
1#matplotlib/axes/_axes.py:Axes.specgram *None* or (xmin, xmax)#tuple(xmin, xmax)#tuple(xmin, xmax)
1#matplotlib/axes/_axes.py:Axes.spy float or 'present', default: 0#Literal['present']#Literal['present']
1#matplotlib/axes/_axes.py:Axes.spy {'equal', 'auto', None} or float, default: 'equal'#Literal['equal', 'auto', None]#Literal['equal', 'auto', None]
1#matplotlib/axes/_base.py:_process_plot_var_args._plot_args result#result#result
1#matplotlib/axes/_base.py:_AxesBase.set_figure `.Figure`#Figure#Figure
1#matplotlib/axes/_base.py:_AxesBase.set_position [left, bottom, width, height] or `~matplotlib.transforms.Bbox`#matplotlib.transforms.Bbox#matplotlib.transforms.Bbox
1#matplotlib/axes/_base.py:_AxesBase.set_position {'both', 'active', 'original'}, default: 'both'#Literal['both', 'active', 'original']#Literal['both', 'active', 'original']
1#matplotlib/axes/_base.py:_AxesBase.set_axes_locator Callable[[Axes, Renderer], Bbox]#Callable[#Callable[
1#matplotlib/axes/_base.py:_AxesBase.set_axes_locator Callable[[Axes, Renderer], Bbox]#tuple(Axes, Renderer], Bbox)#tuple(Axes, Renderer], Bbox)
1#matplotlib/axes/_base.py:_AxesBase._gen_axes_patch Patch#Patch#Patch
1#matplotlib/axes/_base.py:_AxesBase.set_prop_cycle Cycler#Cycler#Cycler
1#matplotlib/axes/_base.py:_AxesBase.set_prop_cycle iterable#iterable#iterable
1#matplotlib/axes/_base.py:_AxesBase.set_aspect {'auto', 'equal'} or float#Literal['auto', 'equal']#Literal['auto', 'equal']
1#matplotlib/axes/_base.py:_AxesBase.set_anchor (float, float) or {'C', 'SW', 'S', 'SE', 'E', 'NE', ...}#Literal['C', 'SW', 'S', 'SE', 'E', 'NE', ...]#Literal['C', 'SW', 'S', 'SE', 'E', 'NE', ...]
1#matplotlib/axes/_base.py:_AxesBase.draw `.RendererBase` subclass.#RendererBase subclass.#RendererBase subclass.
1#matplotlib/axes/_base.py:_AxesBase.grid `.Line2D` properties#Line2D properties#Line2D properties
1#matplotlib/axes/_base.py:_AxesBase.ticklabel_format {'sci', 'scientific', 'plain'}#Literal['sci', 'scientific', 'plain']#Literal['sci', 'scientific', 'plain']
1#matplotlib/axes/_base.py:_AxesBase.ticklabel_format pair of ints (m, n)#pair of ints#pair of ints
1#matplotlib/axes/_base.py:_AxesBase.ticklabel_format pair of ints (m, n)#tuple(m, n)#tuple(m, n)
1#matplotlib/axes/_base.py:_AxesBase.set_xlabel {'left', 'center', 'right'}, default: :rc:`xaxis.labellocation`#Literal['left', 'center', 'right']#Literal['left', 'center', 'right']
1#matplotlib/axes/_base.py:_AxesBase._validate_converted_limits The limit value after call to convert(), or None if limit is None.#The limit value after call to convert#The limit value after call to convert
1#matplotlib/axes/_base.py:_AxesBase._validate_converted_limits The limit value after call to convert(), or None if limit is None.#None if limit is None.#None if limit is None.
1#matplotlib/axes/_base.py:_AxesBase._validate_converted_limits The limit value after call to convert(), or None if limit is None.#tuple()#tuple()
1#matplotlib/axes/_base.py:_AxesBase.set_ylabel {'bottom', 'center', 'top'}, default: :rc:`yaxis.labellocation`#Literal['bottom', 'center', 'top']#Literal['bottom', 'center', 'top']
1#matplotlib/axes/_base.py:_AxesBase._set_view_from_bbox 4-tuple or 3 tuple#4-tuple#4-tuple
1#matplotlib/axes/_base.py:_AxesBase._set_view_from_bbox 4-tuple or 3 tuple#3 tuple#3 tuple
1#matplotlib/axes/_base.py:_AxesBase.contains `matplotlib.backend_bases.MouseEvent`#matplotlib.backend_bases.MouseEvent#matplotlib.backend_bases.MouseEvent
1#matplotlib/axes/_base.py:_AxesBase.get_tightbbox `.RendererBase` subclass#RendererBase subclass#RendererBase subclass
1#matplotlib/axes/_base.py:_AxesBase.get_tightbbox list of `.Artist` or ``None``#list[Artist]#list[Artist]
1#matplotlib/axes/_base.py:_AxesBase.get_tightbbox default: False#default: False#default: False
1#matplotlib/axes/_base.py:_AxesBase.get_tightbbox `.BboxBase`#BboxBase#BboxBase
1#matplotlib/axes/_subplots.py:SubplotBase.__init__ tuple (*nrows*, *ncols*, *index*) or int#tuple(*nrows*, *ncols*, *index*)#tuple(*nrows*, *ncols*, *index*)
1#matplotlib/axes/_secondary_axes.py:SecondaryAxis.set_ticks list of floats#list[floats]#list[floats]
1#matplotlib/axes/_secondary_axes.py:SecondaryAxis.set_functions 2-tuple of func, or `Transform` with an inverse.#Transform with an inverse.#Transform with an inverse.

```
Remember that the type may only represent a part of the sample context; the entire context was potentially turned into a union with the type being just one element. So its a mistake to look at the context and think the type doesn't match *all* of it. 

Our crude normalizer hasn't done too badly; the bulk of these types make sense and many of them are usable as is. Others are clear enough that we could come up with an alternative to map them to.

There's definitely some near the end of the list where we are messing up; I'll look at those in more detail later and see how we can tweak normalization. A typical cause is when my current limitation of only being able to handle one literal or tuple in a type description is violated. E.g. if there is nesting, as in:

```
1#matplotlib/axes/_base.py:_AxesBase.set_axes_locator Callable[[Axes, Renderer], Bbox]#Callable[#Callable[
```

or multiple options, as in:

```
1#matplotlib/axes/_axes.py:Axes.hist2d None or int or [int, int] or array-like or [array, array]#[int#[int
```

Nonetheless, you can see that there are only a little over 200 lines in this map file; considering how long it would take to hand-correct all the types individually and turn them into annotations, versus editing this file and automatically inserting them, this approach should pay off.

## Next Time

That's enough for one day; next time I will look at improving the normalization, collecting a mapping for a whole package, and, finally, applying the types in the mapping file to our stubs.




