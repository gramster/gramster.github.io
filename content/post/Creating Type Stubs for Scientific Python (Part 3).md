---
title: Creating Type Stubs for Scientific Python (Part 3)
date: 2022-09-06T15:36:00
author: Graham Wheeler
category: Programming
comments: enabled
---
## Generating Output for a Whole Package

The approach we took in the last post to finding the files for a package is not strictly correct. We imported the package, then looked at the file associated with the package, and if it was an `__init__.py` file, added all the other `.py` files in the same directory. This works in many cases but not all. It specifically did work for `matplotlib.axes` which is the example I have used until now. I suspect there is probably an elegant solution to finding out when that is appropriate and when it is not, but I don't know what it is. Instead, I am going to treat each `.py` file as an independent module. The old `get_module_and_files` function gets replaced by a function `get_module_and_children`, which returns just a single file, but if that file is an `__init__.py`, also returns all other `.py` files and directories in the same folder in a list of submodules.

```python
def get_module_and_children(m: str) -> tuple[ModuleType|None, str, list[str]]:
    try:
        mod = importlib.import_module(m)
        file = inspect.getfile(mod)
    except Exception as e:
        print(f'Could not import module {m}: {e}')
        return None, None, []

    submodules = []
    if file.endswith("/__init__.py"):
        # Get the parent directory and all the files in that directory
        folder = file[:-12]
        files = []
        for f in glob.glob(folder + "/*"):
            if f == file:
                continue
            if f.endswith('.py'):
                submodules.append(f'{m}.{f[f.rfind("/")+1:-3]}')
            elif os.path.isdir(f) and not f.endswith('__pycache__'):
                submodules.append(f'{m}.{f[f.rfind("/")+1:]}')
    return mod, file, submodules
```

We can then add a flag to the `process_module` function to control whether we want to include submodules:

```python
def process_module(m: str, 
        state: object,
        processor: Callable, 
        targeter: Callable,
        post_processor: Callable|None = None, 
        include_submodules: bool = True,
        **kwargs):

    modules = [m]
    while modules:
        mod, file, submodules = get_module_and_children(modules.pop())
        if include_submodules:
            if not mod:
                continue
            modules.extend(submodules)
        else:
            if not mod:
                return

        result = None

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

```

Now, if we call `process_module('matplotlib')`, we process all modules in the package.


## The Type Translation Function

We've assembled a fair number of components by now, but shouldn't lose sight of the goal while in the weeds. As we generate the stubs, we want a function that essentially takes these inputs:

- the type from the docstring
- whether this is a parameter or a return value/assignment
- the default value (if a parameter or assignment)

and returns the outputs:

- the type annotation
- the (modified) default value (which in most cases should be the same as the input, or '...')
- any imports that are needed to support the type annotation.

Later on we'll use the import info together with the file path to determine what import statements we want to add (favoring relative imports for imports from the same package).

The reason for identifying if this is a parameter versus non-parameter is that we want to be less restrictive with parameters. Let's say a docstring says `list of int`: for a parameter we may want to annotate with `Sequence[int]`, because we just need something that is "list-like", while for the return type it may be reasonable to return `list[int]`, as it is a specific case.

For simplicity, we can split this desired function into separate cases for assignments, parameters and return values, but they will likely share much of their logic.

### Collecting Classes and Import Information

As we analyze types, it is useful to collect what classes are defined in the module. This will also help later to make sure we have the necessary import statements in the stubs. We can add a second dictionary to the state object in the analyzer to keep track of this. We will key it on class names, with the values being the file paths:

```python
    def __init__(self, mod: ModuleType, fname: str, counter: Counter, context: dict,
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
        self._context = context
        self._imports = imports
        
    ...

    def visit_ClassDef(self, node: cst.ClassDef) -> bool:
        if self.at_top_level():
            self._classname = node.name.value
            self._imports[self._classname] = self._fname
            obj = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, node.name.value)
            self._analyze_obj(obj, self._classname)
        return super().visit_ClassDef(node)
```

### Discarding 'Trivial' Analysis Lines

As we generate the map files, there are some types that are obviously correct and need no additional processing or extra imports. Some of these are built-in types, like `float`. Another case is a restricted value that is just a set of possible string values (these are common in matplotlib at least). We can drop these when generating the map file. 

I would have liked to be able to split up the types on " or " and then deal with each alternative as a separate entity. Unfortunately here is where we run into issues with poor specification. It's possible to see types like `list of bool or float`. This is ambiguous, but it probably is meant to imply `list of bool` or `list of float`, as opposed to `list of bool` or `float`. If we simply split at the word `or` we would get the second interpretation, so it is not safe to do this.

Having said that, it is probably okay to do this when the alternatives are single words, such as in `bool or float`, or if they correspond to classes in the package that we have in the map file.

There are also many references to 'array-like' in matplotlib, which we can normalize to ArrayLike.

```python
# Start with {, end with }, comma-separated quoted words
_single_restricted = re.compile(r'^{([ ]*[\"\'][A-Za-z0-9\-_]+[\"\'][,]?)+}$') 


def is_trivial(s):
    if s.lower() in ['float', 'int', 'bool', 'str', 'set', 'list', 'dict', 'tuple', 'callable', 'array-like', 'none']:
        return True

    if _single_restricted.match(s):
        return True

    if s.find(' or ') > 0:
        if all([is_redundant(c.strip()) for c in s.split(' or ')]):
            return True
        
    return False

```

Skipping such types reduces our output to 154 lines:

```
19##
14#1-D array#1-D array
10#1D or 2D array-like#1D|2D array-like
9#(float, float)#tuple[float, float]
8#indexable object#indexable object
7#color#color
7#`~matplotlib.lines.Line2D`#matplotlib.lines.Line2D
7#callable or ndarray#callable|ndarray
6#list of `.Line2D`#Sequence[Line2D]
6#array (length N) or scalar#array|scalar|tuple[length N]
5#str or `~matplotlib.colors.Colormap`#str|matplotlib.colors.Colormap
5#`~matplotlib.colors.Normalize`#matplotlib.colors.Normalize
5#1-D array or sequence#1-D array|sequence
4#(M, N) array-like#ArrayLike|tuple[M, N]
4#Transform#Transform
3#`.Bbox`#Bbox
3#`.BarContainer`#BarContainer
3#float or array-like, shape (n, )#float|ArrayLike|shape|tuple[n, ]
3#color or color sequence#color|color sequence
3#array (length N)#array|tuple[length N]
3#array of bool (length N)#Sequence[bool]|tuple[length N]
3#`.PolyCollection`#PolyCollection
3#2D array-like#2D array-like
3#array-like, shape (n, )#ArrayLike|shape|tuple[n, ]
3#`~.axes.Axes`#axes.Axes
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
2#`~matplotlib.collections.LineCollection`#matplotlib.collections.LineCollection
2#array-like or scalar#ArrayLike|scalar
2#sequence#sequence
2#array (length ``2*maxlags+1``)#array|tuple[length ``2*maxlags+1``]
2#array  (length ``2*maxlags+1``)#array|tuple[length ``2*maxlags+1``]
2#`.LineCollection` or `.Line2D`#LineCollection|Line2D
2#`.Line2D` or None#Line2D|None
2#array-like of length n#array-like of length n
2#1D array-like#1D array-like
2#float or array-like, shape(N,) or shape(2, N)#float|ArrayLike|shape(N|)|shape|tuple[2, N]
2#int or (int, int)#int|tuple[int, int]
2#Array or a sequence of vectors.#Array|a sequence of vectors.
2#list of dicts#Sequence[dicts]
2#`~matplotlib.image.AxesImage`#matplotlib.image.AxesImage
2#{'none', None, 'face', color, color sequence}#Literal['none', None, 'face', color, color sequence]
2#`~.contour.QuadContourSet`#contour.QuadContourSet
2#2D array#2D array
2#1D array#1D array
2#1-D arrays or sequences#1-D arrays|sequences
2#float greater than -0.5#float greater than -0.5
2#bool or 'line'#bool|Literal['line']
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
1#array-like or list of array-like#ArrayLike|list of array-like
1#color or list of colors#color|Sequence[colors]
1#str or tuple or list of such values#str|tuple|list of such values
1#list of `.EventCollection`#Sequence[EventCollection]
1#timezone string or `datetime.tzinfo`#timezone string|datetime.tzinfo
1#list of `.Text`#Sequence[Text]
1#sequence of tuples (*xmin*, *xwidth*)#Sequence[tuples]|tuple[*xmin*, *xwidth*]
1#(*ymin*, *yheight*)#tuple[*ymin*, *yheight*]
1#`~.collections.BrokenBarHCollection`#collections.BrokenBarHCollection
1#`.StemContainer`#StemContainer
1#`.ErrorbarContainer`#ErrorbarContainer
1#float or (float, float)#float|tuple[float, float]
1#color or sequence or sequence of color or None#color|sequence|Sequence[color]|None
1#color or sequence of color or {'face', 'none'} or None#color|Sequence[color]|None|Literal['face', 'none']
1#c#c
1#array(N, 4) or None#array|None|tuple[N, 4]
1#edgecolors#edgecolors
1#array-like or list of colors or color#ArrayLike|Sequence[colors]|color
1#`~.markers.MarkerStyle`#markers.MarkerStyle
1#{'face', 'none', *None*} or color or sequence of color#color|Sequence[color]|Literal['face', 'none', *None*]
1#`~matplotlib.collections.PathCollection`#matplotlib.collections.PathCollection
1#'log' or int or sequence#Literal['log']|int|sequence
1#int > 0#int > 0
1#4-tuple of float#4-tuple of float
1#`~matplotlib.collections.PolyCollection`#matplotlib.collections.PolyCollection
1#`.FancyArrow`#FancyArrow
1#`matplotlib.quiver.Quiver`#matplotlib.quiver.Quiver
1#`~matplotlib.quiver.Quiver`#matplotlib.quiver.Quiver
1#bool or array-like of bool#bool|array-like of bool
1#`~matplotlib.quiver.Barbs`#matplotlib.quiver.Barbs
1#sequence of x, y, [color]#Sequence[x]|y|tuple[color]
1#list of `~matplotlib.patches.Polygon`#Sequence[matplotlib.patches.Polygon]
1#{{'pre', 'post', 'mid'}}#{|Literal['pre', 'post', 'mid'}]
1#array-like or PIL image#ArrayLike|PIL image
1#floats (left, right, bottom, top)#floats|tuple[left, right, bottom, top]
1#float > 0#float > 0
1#`matplotlib.collections.Collection`#matplotlib.collections.Collection
1#`matplotlib.collections.QuadMesh`#matplotlib.collections.QuadMesh
1#`.AxesImage` or `.PcolorImage` or `.QuadMesh`#AxesImage|PcolorImage|QuadMesh
1#`.ContourSet` instance#ContourSet instance
1#(n,) array or sequence of (n,) arrays#(n|) array|sequence of  arrays|tuple[n,]
1#int or sequence or str#int|sequence|str
1#(n,) array-like or None#ArrayLike|None|tuple[n,]
1#bool or -1#bool|Literal[-1]
1#array-like, scalar, or None#ArrayLike|scalar|None
1#color or array-like of colors or None#color|array-like of colors|None
1#array or list of arrays#array|Sequence[arrays]
1#array#array
1#`.BarContainer` or list of a single `.Polygon` or list of such objects#BarContainer|list of a single .Polygon|list of such objects
1#float, array-like or None#float|ArrayLike|None
1#`matplotlib.patches.StepPatch`#matplotlib.patches.StepPatch
1#None or int or [int, int] or array-like or [array, array]#None|int|[int|int]|ArrayLike|tuple[array, array]
1#array-like shape(2, 2)#array-like shape|tuple[2, 2]
1#`~.matplotlib.collections.QuadMesh`#matplotlib.collections.QuadMesh
1#`.Colormap`#Colormap
1#*None* or (xmin, xmax)#*None*|tuple[xmin, xmax]
1#`.AxesImage`#AxesImage
1#float or 'present'#float|Literal['present']
1#{'equal', 'auto', None} or float#float|Literal['equal', 'auto', None]
1#`~matplotlib.image.AxesImage` or `.Line2D`#matplotlib.image.AxesImage|Line2D
1#str, scalar or callable#str|scalar|callable
1#result#result
1#`~matplotlib.figure.Figure`#matplotlib.figure.Figure
1#[left, bottom, width, height]#tuple[left, bottom, width, height]
1#`.Figure`#Figure
1#[left, bottom, width, height] or `~matplotlib.transforms.Bbox`#matplotlib.transforms.Bbox|tuple[left, bottom, width, height]
1#Callable[[Axes, Renderer], Bbox]#Callable[|tuple[Axes, Renderer], Bbox]
1#Patch#Patch
1#Cycler#Cycler
1#iterable#iterable
1#None or str or (float, float)#None|str|tuple[float, float]
1#(float, float) or {'C', 'SW', 'S', 'SE', 'E', 'NE', ...}#Literal['C', 'SW', 'S', 'SE', 'E', 'NE', ...]|tuple[float, float]
1#`.RendererBase` subclass.#RendererBase subclass.
1#`.Line2D` properties#Line2D properties
1#pair of ints (m, n)#pair of ints|tuple[m, n]
1#The limit value after call to convert(), or None if limit is None.#The limit value after call to convert|None if limit is None.|tuple[]
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

We can extend this further by dropping any types that are just classes we collected in our earlier section. This makes the most sense when processing a whole package (so we gather all the possible classes from the package). If I run the analyzer on all of `matplotlib`, I reduce the output from about 690 lines down to about 530.

```python
def is_trivial(s, m: str, classes: set = None):

    if s.find(' or ') > 0:
        if all([is_trivial(c.strip(), m, classes) for c in s.split(' or ')]):
            return True

    if _single_restricted.match(s):
        return True

    nt = normalize_type(s)

    if nt.lower() in ['float', 'int', 'bool', 'str', 'set', 'list', 'dict', 'tuple', 'array-like', 
                     'callable', 'none']:
        return True

    if classes:
        # Check unqualified classname

        if nt in classes: # 
            return True

        # Check full qualified classname
        if nt.startswith(m + '.'):
            if nt[nt.rfind('.')+1:] in classes:
                return True

    return False
    
...

def _post_process(m: str, state: tuple):
    result = ''
    freq: Counter = state[0]
    imports: dict = state[1]
    classes: set = set(imports.keys())
    for typ, cnt in freq.most_common():
        if not is_trivial(typ, m, classes):
            result += f'{cnt}#{typ}#{normalize_type(typ)}\n'
    return result

```
### Persistent Maps

We could press on with reducing the output from analysis and there's some value in doing that, because all the remaining entries are going to need human inspection to come up with an equivalent type annotation. But we are at the point of diminishing returns now, where the risk is we will exclude ambiguous lines and end up with bad annotations (there's already a small risk of this from our last step if there are classes with identical names).

Instead, let's put the various pieces together to create the type translation function. As a precursor to calling this function, we would run the analysis phase to get the classes and collect all the 'non-trivial' types. We can then load a persistent map file (which would be a human-edited output from an earlier analysis), to find even more annotations. Anything that is either non-trivial or missing from the persistent map file would be unhandled, and we can output those entries so they can be added to the map file for the next iteration.

There's a lot of changes needed for all of this, and rather than do them iteratively I'll show the end result.

Note: I store a lot of metadata from the analysis transformer for use by the stubbing transformer. LibCST has a metadata mechanism that would probably make all of this simpler, but frankly, I find the documentation next to useless, so I implemented my own. I mostly just rely on dictionaries that are keyed on 'contexts'.

First, `utils.py`:

```python
from genericpath import isdir
import glob
import importlib
import inspect
import os
import re
from types import ModuleType
from typing import Callable
from .normalize import normalize_type


def load_map(m: str):
    map = {}
    mapfile = f"analysis/{m}.map"
    if os.path.exists(mapfile):
        with open(mapfile) as f:
            for line in f:
                parts = line.strip().split('#')
                map[parts[0]] = parts[1]
    return map


def get_module_and_children(m: str) -> tuple[ModuleType|None, str, list[str]]:
    try:
        mod = importlib.import_module(m)
        file = inspect.getfile(mod)
    except Exception as e:
        print(f'Could not import module {m}: {e}')
        return None, None, []

    submodules = []
    if file.endswith("/__init__.py"):
        # Get the parent directory and all the files in that directory
        folder = file[:-12]
        files = []
        for f in glob.glob(folder + "/*"):
            if f == file:
                continue
            if f.endswith('.py'):
                submodules.append(f'{m}.{f[f.rfind("/")+1:-3]}')
            elif os.path.isdir(f) and not f.endswith('__pycache__'):
                submodules.append(f'{m}.{f[f.rfind("/")+1:]}')
    return mod, file, submodules


def process_module(m: str, 
        state: object,
        processor: Callable, 
        targeter: Callable,
        post_processor: Callable|None = None, 
        include_submodules: bool = True,
        **kwargs):

    modules = [m]
    while modules:
        m = modules.pop()
        mod, file, submodules = get_module_and_children(m)
        if include_submodules:
            if not mod:
                continue
            modules.extend(submodules)
        else:
            if not mod:
                return

        result = None

        try:
            with open(file) as f:
                source = f.read()
        except Exception as e:
            print(f"Failed to read {file}: {e}")
            continue

        result = processor(mod, m, file, source, state, **kwargs)
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
        result, rtn = post_processor(m, state)
        if result:
            target = targeter(m)
            folder = target[: target.rfind("/")]
            os.makedirs(folder, exist_ok=True)
            with open(target, "w") as f:
                f.write(result)
        return rtn
    return None


# Start with {, end with }, comma-separated quoted words
_single_restricted = re.compile(r'^{([ ]*[\"\'][A-Za-z0-9\-_]+[\"\'][,]?)+}$') 


def is_trivial(s, m: str, classes: set|dict = None):
    """
    s - the type docstring to check
    m - the module name
    classes - a set of class names or dictionary keyed on classnames 
    """

    if s.find(' or ') > 0:
        if all([is_trivial(c.strip(), m, classes) for c in s.split(' or ')]):
            return True

    if _single_restricted.match(s):
        return True

    nt = normalize_type(s)

    if nt.lower() in ['float', 'int', 'bool', 'str', 'set', 'list', 'dict', 'tuple', 'array-like', 
                     'callable', 'none']:
        return True

    if classes:
        # Check unqualified classname

        if nt in classes: # 
            return True

        # Check full qualified classname
        if nt.startswith(m + '.'):
            if nt[nt.rfind('.')+1:] in classes:
                return True

    return False


_generic_type_map = {
    'float': 'float',
    'int': 'int',
    'bool': 'bool',
    'str': 'str',
    'dict': 'dict',
    'list': 'list',
}

_generic_import_map = {

}
```

Then, the `analyzer.py`:

```python
from ast import Num
from collections import Counter
import inspect
import json
import os
from types import ModuleType
from xml.etree.ElementInclude import include
import libcst as cst
from .basetransformer import BaseTransformer
from .utils import process_module, is_trivial, load_map
from .parser import NumpyDocstringParser
from .normalize import normalize_type

class AnalyzingTransformer(BaseTransformer):

    def __init__(self, 
            mod: ModuleType, 
            modname: str,
            fname: str, 
            counter: Counter,
            classes: dict,
            docs: dict):
        super().__init__(modname, fname)
        self._mod = mod
        self._parser = NumpyDocstringParser()
        self._counter = counter
        self._classes = classes
        self._docs = {}
        docs[modname] = self._docs
        self._classname = None
        

    def _analyze_obj(self, obj, context: str) -> tuple[dict[str, str]|None, ...]:
        doc = None
        if obj:
            doc = inspect.getdoc(obj)
        if not doc:
            return
        rtn = self._parser.parse(doc)
        for section in rtn:
            if section:
                for typ in section.values():
                    self._counter[typ] += 1
        return rtn

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
        rtn = super().visit_ClassDef(node)
        if self.at_top_level_class_level():
            self._classname = node.name.value
            self._classes[self._classname] = self._modname
            obj = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, node.name.value)
            self._docs[self.context()] = self._analyze_obj(obj, self._classname)
        return rtn

    def visit_FunctionDef(self, node: cst.FunctionDef) -> bool:
        outer_context = self.context()
        rtn = super().visit_FunctionDef(node)
        name = node.name.value
        obj = None
        context = self.context()
        if self.at_top_level_function_level():
            #context = name
            obj = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, name)
        elif self.at_top_level_class_method_level():
            #context = f'{self._classname}.{name}'
            parent = AnalyzingTransformer.get_top_level_obj(self._mod, self._fname, self._classname)
            if parent:
                if name in parent.__dict__:
                    obj = parent.__dict__[name]
                else:
                    print(f'{self._fname}: Could not get obj for {context}')
        docs = self._analyze_obj(obj, context)
        self._docs[context] = docs

        if name == '__init__':
            # If we actually had a docstring with params section, we're done
            if docs and docs[0]:
                return rtn
            # Else use the class docstring for __init__
            self._docs[context] = self._docs.get(outer_context)

        return rtn

    def leave_FunctionDef(
        self, original_node: cst.FunctionDef, updated_node: cst.FunctionDef
    ) -> cst.CSTNode:
        # Add a special entry for the return type
        context = self.context()
        doc = self._docs[context]
        if doc:
            self._docs[context + '->'] = doc[1]
        return super().leave_FunctionDef(original_node, updated_node)

    def visit_Param(self, node: cst.Param) -> bool:
        parent_context = self.context()
        parent_doc = self._docs.get(parent_context)
        rtn = super().visit_Param(node)
        if parent_doc and not isinstance(parent_doc, str):
             # The string check makes sure it's not a parameter of a lambda or function that was 
             # assigned as a default value of some other parameter
            param_docs = parent_doc[0]
            if param_docs:
                try:
                    self._docs[self.context()] = param_docs.get(node.name.value)
                except Exception as e:
                    print(e)
        return rtn


def _analyze(mod: ModuleType, m: str, fname: str, source: str, state: tuple, **kwargs):
    try:
        cstree = cst.parse_module(source)
    except Exception as e:
        return None
    try:
        patcher = AnalyzingTransformer(mod, m, fname, 
            counter=state[0], 
            classes = state[1],
            docs = state[2])
        cstree.visit(patcher)
    except:  # Exception as e:
        # Note: I know that e is undefined below; this actually lets me
        # successfully see the stack trace from the original exception
        # as traceback.print_exc() was not working for me.
        print(f"Failed to analyze file: {e}")
        return None
    return state


def _post_process(m: str, state: tuple):
    map = load_map(m)
    result = ''
    freq: Counter = state[0]
    classes: dict = state[1]
    docs: dict = state[2]
    for typ, cnt in freq.most_common():
        if typ not in map and not is_trivial(typ, m, classes):
            result += f'{typ}#{normalize_type(typ)}\n'
    return result, (map, classes, docs)


def _targeter(m: str) -> str:
    """ Turn module name into map file name """
    return f"analysis/{m}.map.missing"


def analyze_module(m: str, include_submodules: bool = True):
    return process_module(m, (Counter(), {}, {}), _analyze, _targeter, post_processor=_post_process,
        include_submodules=include_submodules)


```

And then, the updated `stubber.py`:

```python
from __future__ import annotations
from asyncio.proactor_events import _ProactorBaseWritePipeTransport
import glob
import inspect
import os
import re
from types import ModuleType
import libcst as cst

from docs2stubs.analyzer import analyze_module
from docs2stubs.normalize import normalize_type
from .basetransformer import BaseTransformer
from .utils import is_trivial, process_module


class StubbingTransformer(BaseTransformer):
    def __init__(self, modname: str, fname: str, map: dict, classes: dict, docs: dict, 
        strip_defaults=False, infer_types_from_defaults=False):
        super().__init__(modname, fname)
        self._map = map
        self._classes = classes
        self._docs = docs[modname]
        self._strip_defaults = strip_defaults
        self._infer_types = infer_types_from_defaults
        self._method_names = set()
        self._local_class_names = set()
        self._need_imports = {}
        self._ident_re = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)')

    @staticmethod
    def get_value_type(node: cst.CSTNode) -> str|None:
        typ: str|None= None
        if isinstance(node, cst.Name):
            if node.value in [ 'True', 'False']:
                typ = 'bool'
            elif node.value == 'None':
                typ = 'None'
        else:
            for k, v in {
                cst.Integer: 'int',
                cst.Float: 'float',
                cst.Imaginary: 'complex',
                cst.BaseString: 'str',
                cst.BaseDict: 'dict',
                cst.BaseList: 'list',
                cst.BaseSlice: 'slice',
                cst.BaseSet: 'set',
                # TODO: check the next two
                cst.Lambda: 'Callable',
                cst.MatchPattern: 'pattern'
            }.items():
                if isinstance(node, k):
                    typ = v
                    break
        return typ

    def get_assign_value(self, node: cst.Assign) -> cst.CSTNode:
        # See if this is an alias, in which case we want to
        # preserve the value; else we set the new value to ...
        new_value = None
        if isinstance(node.value, cst.Name) and not self.in_function():
            check = set()
            if self.at_top_level():
                check = self._local_class_names
            elif self.at_top_level_class_level(): # Class level
                check = self._method_names
            if node.value.value in check:
                new_value = node.value
        if new_value is None:
            new_value = cst.parse_expression("...")  
        return new_value

    def get_assign_props(self, node: cst.Assign) -> tuple(str|None, cst.CSTNode):
         typ = StubbingTransformer.get_value_type(node.value)
         value=self.get_assign_value(node)
         return typ, value

    def leave_Assign(
        self, original_node: cst.Assign, updated_node: cst.Assign
    ) -> cst.CSTNode:
        typ, value = self.get_assign_props(original_node)
        typ = StubbingTransformer.get_value_type(original_node.value)
        # Make sure the assignment was not to a tuple before
        # changing to AnnAssign
        # TODO: if this is an attribute, see if it had an annotation in 
        # the class docstring and use that
        if typ is not None and len(original_node.targets) == 1:
            return cst.AnnAssign(target=original_node.targets[0].target,
                annotation=cst.Annotation(annotation=cst.Name(typ)),
                value=value)
        else:
            return updated_node.with_changes(value=value)

    def leave_AnnAssign(
        self, original_node: cst.Assign, updated_node: cst.Assign
    ) -> cst.CSTNode:
        value=self.get_assign_value(original_node)
        return updated_node.with_changes(value=value)

    def leave_Param(
        self, original_node: cst.Param, updated_node: cst.Param
    ) -> cst.CSTNode:
        doctyp = self._docs.get(self.context())
        super().leave_Param(original_node, updated_node)
        annotation = original_node.annotation
        default = original_node.default
        valtyp = None
        is_optional = False

        if default:
            valtyp = StubbingTransformer.get_value_type(default) # Inferred type from default
            if (not valtyp or self._strip_defaults):
                # Default is something too complex for a stub or should be stripped; replace with '...'
                default = cst.parse_expression("...")

        if doctyp and not annotation:
            typ = None
            if doctyp in self._map:
                typ = self._map[doctyp]
            elif is_trivial(doctyp, self._modname, self._classes):
                typ = normalize_type(doctyp)
            if typ:
                if typ.find('list') >= 0:
                    # Make this more robust
                    typ = typ.replace('list', 'Sequence')
                    self._need_imports['Sequence'] = 'typing'
                # Figure out other needed imports. A crude but maybe good
                # enough approach is to search for identifiers with a regexp, and
                # then add those if they are in the imports dict.
                for m in self._ident_re.findall(typ):
                    if m in ['Any', 'Callable', 'Iterable', 'Literal', 'Sequence']:
                        self._need_imports[m] = 'typing'
                    elif m in self._classes and m not in self._local_class_names:
                        self._need_imports[m] = self._classes[m]

                # If the default value is None, make sure we include it in the type
                is_optional = 'None' in typ.split('|')
                if not is_optional and valtyp == 'None':
                    typ = typ + '|None'

                print(f'Annotated {self.context()} with {typ} from {doctyp}')
                annotation = cst.Annotation(annotation=cst.parse_expression(typ))
            else:
                print(f'Could not annotate {self.context()} from {doctyp}')

        if self._infer_types and valtyp and not annotation and valtyp != 'None':
            # Use the inferred type from default value as long as it is not None
            annotation = cst.Annotation(annotation=cst.Name(valtyp))
            
        return updated_node.with_changes(annotation=annotation, default=default)

    def visit_ClassDef(self, node: cst.ClassDef) -> bool:
        # Record the names of top-level classes
        if not self.in_class():
            self._local_class_names.add(node.name.value)
        return super().visit_ClassDef(node)

    def leave_ClassDef(self, original_node: cst.ClassDef, updated_node: cst.ClassDef) -> cst.CSTNode:
        super().leave_ClassDef(original_node, updated_node)
        if not self.in_class():
            # Clear the method name set
            self._method_names = set()
            return updated_node
        else:
            # Nested class; return ...
            return cst.parse_statement('...')

    def visit_FunctionDef(self, node: cst.FunctionDef) -> bool:
        if self.at_top_level_class_level():
            # Record the method name
            self._method_names.add(node.name.value)
        return super().visit_FunctionDef(node)

    def leave_FunctionDef(
        self, original_node: cst.FunctionDef, updated_node: cst.FunctionDef
    ) -> cst.CSTNode:
        """Remove function bodies"""
        doctyp = self._docs.get(self.context() + '->')
        annotation = original_node.returns
        super().leave_FunctionDef(original_node, updated_node)
        if self.in_function(): 
            # Nested function; return ...
            return cst.parse_statement('...')

        if not annotation and doctyp:
            if all([t in self._map or is_trivial(t, self._modname, self._classes) for t in doctyp.values()]):
                v = [self._map[t] if t in self._map else normalize_type(t) for t in doctyp.values()]
                if len(v) > 1:
                    rtntyp = 'tuple[' + ', '.join(v) + ']'
                else:
                    rtntyp = v[0]
                print(f'Annotating {self.context()}-> as {rtntyp}')   
                return updated_node.with_changes(body=cst.parse_statement("..."), 
                    returns=cst.Annotation(annotation=cst.parse_expression(rtntyp)))    
            else:
                print(f'Could not annotate {self.context()}-> from {doctyp}') 

        # Remove the body only
        return updated_node.with_changes(body=cst.parse_statement("..."))

    def leave_SimpleStatementLine(
        self,
        original_node: cst.SimpleStatementLine,
        updated_node: cst.SimpleStatementLine,
    ) -> cst.CSTNode:
        newbody = [
            node
            for node in updated_node.body
            if any(
                isinstance(node, cls)
                for cls in [cst.Assign, cst.AnnAssign, cst.Import, cst.ImportFrom]
            )
        ]
        return updated_node.with_changes(body=newbody)

    def leave_Module(
        self, original_node: cst.Module, updated_node: cst.Module
    ) -> cst.Module:
        """Remove everything from the body that is not an import,
        class def, function def, or assignment.
        """
        newbody = [
            node
            for node in updated_node.body
            if any(
                isinstance(node, cls)
                for cls in [cst.ClassDef, cst.FunctionDef, cst.SimpleStatementLine]
            )
        ]
        return updated_node.with_changes(body=newbody)


def patch_source(m: str, fname: str, source: str, map: dict, imports: dict, docs: dict, strip_defaults: bool = False) -> str|None:
    try:
        cstree = cst.parse_module(source)
    except Exception as e:
        return None

    patcher = StubbingTransformer(m, fname, map, imports, docs, strip_defaults=strip_defaults)
    modified = cstree.visit(patcher)

    imports = ''
    for module in set(patcher._need_imports.values()):
        typs = []
        for k, v in patcher._need_imports.items():
            if v == module:
                typs.append(k)
        # TODO: make these relative imports if appropriate
        imports += f'from {module} import {",".join(typs)}\n'
    if imports:
        return imports + '\n\n' + modified.code

    return modified.code


def _stub(mod: ModuleType, m: str, fname: str, source: str, state: tuple, **kwargs):
    return patch_source(m, fname, source, state[0], state[1], state[2], **kwargs)

def _targeter(fname: str) -> str:
    return "typings/" + fname[fname.find("/site-packages/") + 15 :] + "i"

def stub_module(m: str, include_submodules: bool = True, strip_defaults: bool = False):
    map, imports, docs = analyze_module(m, include_submodules=include_submodules)
    process_module(m, (map, imports, docs), _stub, _targeter, include_submodules=include_submodules,
        strip_defaults=strip_defaults)

```

At some point I want to write some code that will populate the map file for `matplotlib` from the stubs I have already created. However, the process above will never match what I did earlier, because it still relies on their being appropriate docstrings with types before it will add annotations. At best, this code will annotate every parameter and return type that is 'properly' documented, but nothing more. When I created the `matplotlib` stubs, I started using context that I learned over time. For example, I recognized that a parameter named `gc` represented a `GraphicsContext` even if this wasn't otherwise documented. We could enhance this code to do something similar, but its still going to be quite dumb compared to a human that can apply judgement. So it's unlikely I will ever use this code to matplotlib stubs. However, it could be a great tool for other libraries for which we have no stubs. I'll be applying it next to scikit-learn and seeing how that goes, and will describe that in my next post.

