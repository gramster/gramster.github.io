---
title: Creating Type Stubs for Scientific Python (Part 4)
date: 2022-12-03T11:36:00
author: Graham Wheeler
category: Programming
comments: enabled
---
## The Story Thus Far

Its been a while since the last post, mainly because I hit a speed bump along the way, which I have since addressed. It's worth recapping what was covered
before.

- Scientific Python pacckages like matplotlib don't have much in the way of inline type annotations, nor do they have good type stubs available, but
those would be very useful to improve the experience using them in code editors
- they *do* have a standard form of docstrings, numpydoc format, and that includes parameter and return value descriptions that most of the time
include descriptions of the types (albeit in an informal way)
- I decided to build a tool to extract these and try to convert them to formal type annotations and generate stubs
- the extraction part, and the 'insert converted annotations in to make stubs' part, are reasonably straightforward, thanks in particular to Instagram's
libCST library for concrete syntax tree visiting and transforming
- I write the extracted descriptions plus my best effort at turning these into formal types into '.map' files, as part of an analysis phase; these are read
back in and used during the stub generation phase. This provides the opportunity to examine the automated translation and make hand-corrections before
generating the stubs. The corrected map files can be re-used when new package versions are released; the analysis phase will write any *new* type descriptions
it sees to 'map.missing' files while ignoring those in existing '.map' files; the '.map' files can then be updated with the new types in the '.missing' file
- I dedup and aggregate the types, so the '.map' files also include a frequency count. This can reduce the number of types in the map files from thousands
to hundreds, making the hand checking stage a much more tractable problem.
- I further reduce the size of the map files by looking for cases that seem really trivial, and not including them; I will just convert them based on the
trivial conversion when I create te stubs. For example, 'float' or 'int', or 'array of float', etc.

I started out looking at matplotlib and all the above was working well. However, when I looked at other libraries like SciPy and sklearn, I found a much
bigger variety of forms in the docstring comments and my approach broke down.

## What Went Wrong

There's nothing wrong with my overall process; the challenge came down to two key functions:

- `is_trivial` takes a docstring type comment and returns whether or not it is trivial enough that we don't need to write it to the map file
- `normalize_type` translates the docstring comment to a formal type annotation, if it can

These relied heavily on regular expressions that were shaped by what I was seeing in the matplotlib comments. Once I tried the code on other libraries, I had
two serious breakdowns:

- `is_trivial` admitted a lot of false positives; i.e. it thought a type was trivial when it was actually ambiguous. Think about something like
'list of int or float'. This could be interpreted as `list[int|float]` or `list[int]|float` There is no way to tell what was intended! This *has* to 
go in the map file and be checked by hand.
- `normalize_type` failed on so many types that I wasn't actually getting a lot of type annotations out of the docstrings.

The functions were already reasonably complex, leveraging a large set of regular expressions, and I just felt that trying to fix them by continuing
down the regular expression route was asking for trouble. Certainly for `normalize_type`; I could keep using regular expressions for `is_trivial` but I
clearly needed to raise the bar and become a lot more strict.

## A Parser to the Rescue

My knowledge about parsers mostly dates back to the '90s, when I used to teach under- and post-graduate courses in compiler construction at the University of 
Cape Town. Back in those days, constructing parsers was non-trivial; we had tools that could take formal grammars and turn them into parsers, but you had to
spend quite a bit of time eliminating the wrong types of recursiveness from your grammar. It wasn't always possible, and it was often tedious. I knew that
the technology had advanced; we were largely stuck with single-token lookahead but then [Antlr](https://www.antlr.org/) came along and allowed us to go from LL(1) or LR(1) to LL(k)
(if you don't understand these terms don't worry about it). More recently I knew Guido had rewritten Python's parser using a 'PEG parser'; I didn't really 
know much about them other that they seemed to allow a lot more grammar flexibility. So I started trying to come up with a grammar for the docstrings (if
this sounds crazy to you, yeah, it kinda is), and using the Python PEG parser generator. I quickly discovered that that parser generator was pretty much 
intended for CPython and wasn't going to work, but then I discovered [Lark](https://lark-parser.readthedocs.io/en/latest/), which can parse *any* context-free
grammar, according to the docs. I thought my prayers had been answered, and indeed they have, at the expense of computation time. Lark is fantastic. I 
have thrown the most ungodly awful grammar at it and it is working great.

## A Grammar from Hell

My process was pretty simple: take the types from the map files, and throw them at my elvolving grammar, and iterate on the grammar on each failure (or 
decide that the particular failing case wasn't worth the effort). In the end I got to about a 75% success rate, and the AST's that are produced in this
process are for the most part pretty good at describing the type unambiguously. I don't think I could ask for much more, and I would get diminishing
returns at this point. It might at some point be interesting to use the map files to train an ML model and see how that compares, but I'm in no 
hurry to do that. So below, is the grammar of my nightmares. The evilness is mostly around arrays and the multivariate ways they can be expressed:

```
start: type_list
type_list: [RETURNS] type ((_COMMA|OR|_COMMA OR) type)* [_PERIOD|_COMMA] [[_LPAREN] DEFAULT [_EQUALS|_COLON] literal_type [_RPAREN] [_PERIOD]]
type: array_type 
    | basic_type [TYPE]
    | callable_type 
    | class_type 
    | dict_type 
    | filelike_type
    | generator_type 
    | iterable_type
    | iterator_type
    | literal_type 
    | optional_type 
    | restricted_type 
    | set_type
    | tuple_type 
    | union_type 
    | _LESSTHAN type _GRTRTHAN
array_type: [NDARRAY|NUMPY] basic_type [_MINUS] array_kind [[_COMMA] (dimension | shape_qualifier)]
          | [dimension] array_kinds [_COMMA] shape_qualifier [[_COMMA] type_qualifier] 
          | [dimension] array_kinds [_COMMA] type_qualifier [[_COMMA] shape_qualifier] 
          | shape basic_type array_kind
          | dimension basic_type array_kind
          | shape_qualifier array_kind [type_qualifier]
          | type_qualifier array_kind [shape_qualifier]
          | [dimension] array_kind
array_kinds: array_kind | _LBRACE array_kind [ _COMMA array_kind]* _RBRACE
array_kind: [A|AN] [SPARSE | _LPAREN SPARSE _RPAREN] ARRAYLIKE
          | [A] LIST
          | [A|AN] NDARRAY 
          | [A] [SPARSE | _LPAREN SPARSE _RPAREN] MATRIX [CLASS]
          | [A] SEQUENCE
          | [A|AN] [SPARSE | _LPAREN SPARSE _RPAREN] ARRAY 
          | ARRAYS 
          | SPARSE
dimension: _DIM ((OR | _SLASH) _DIM)* 
        | (NUMBER|NAME) _X (NUMBER|NAME) 
        | _LPAREN (NUMBER|NAME) _COMMA [NUMBER|NAME] [_COMMA [NUMBER|NAME]] _RPAREN
        | ONED
        | TWOD
        | THREED
shape_qualifier: [[WITH|OF] SHAPE] [_EQUALS|OF] (SIZE|LENGTH) (QUALNAME|NUMBER|shape)
               | [[WITH|OF] SHAPE] [_EQUALS|OF] shape (OR shape)* [dimension]
               | SAME SHAPE AS QUALNAME
               | OF SHAPE QUALNAME
shape: (_LPAREN|_LBRACKET) shape_element (_COMMA shape_element)* _COMMA? (_RPAREN|_RBRACKET)
shape_element: (QUALNAME|NUMBER|_ELLIPSIS) [[_MINUS|_PLUS] NUMBER]
type_qualifier: OF (ARRAYS|ARRAYLIKE)
              | OF [NUMBER] type 
              | [OF] DTYPE [_EQUALS] (basic_type | QUALNAME) [TYPE]
              | _LBRACKET type _RBRACKET
              | _LPAREN type _RPAREN
basic_type.2: ANY 
            | [POSITIVE|NEGATIVE] INT [_GRTRTHAN NUMBER]
            | STR 
            | [POSITIVE|NEGATIVE] FLOAT [IN _LBRACKET NUMBER _COMMA NUMBER _RBRACKET] [_GRTRTHAN NUMBER]
            | BOOL
            | [NUMPY] SCALAR [VALUE]
            | COMPLEX [SCALAR]
            | OBJECT
            | FILELIKE
            | PATHLIKE
            | [NUMPY] DTYPE
callable_type: CALLABLE [_LBRACKET [_LBRACKET type_list _RBRACKET _COMMA] type _RBRACKET]
class_type: [CLASSMARKER] class_specifier [INSTANCE|OBJECT]
        | class_specifier [_COMMA|_LPAREN] OR SUBCLASS [_RPAREN]
        | class_specifier [_COMMA|_LPAREN] OR class_specifier[_RPAREN]
class_specifier: [A|AN] (INSTANCE|CLASS|SUBCLASS) OF QUALNAME 
        | [A|AN] QUALNAME (INSTANCE|CLASS|SUBCLASS)
        | [A|AN] QUALNAME [_COMMA|_LPAREN] OR [A|AN|ANOTHER] SUBCLASS [OF QUALNAME][_RPAREN]
        | [A|AN] QUALNAME [_COLON QUALNAME] [_MINUS LIKE]
dict_type: (MAPPING|DICT) (OF|FROM) (basic_type|qualname) [(TO|_ARROW) (basic_type|qualname)] 
         | (MAPPING|DICT) [_LBRACKET type _COMMA type _RBRACKET]
filelike_type: [READABLE|WRITABLE] FILELIKE [TYPE]
generator_type: GENERATOR [OF type]
iterable_type: ITERABLE [(OF|OVER) type]
         | ITERABLE _LPAREN type _RPAREN
iterator_type: ITERATOR [(OF|OVER) type]
         | ITERATOR _LPAREN type _RPAREN
literal_type: STRING | NUMBER | NONE | TRUE | FALSE
optional_type: OPTIONAL [_LBRACKET type _RBRACKET]
restricted_type: [(ONE OF)| STR] _LBRACE (literal_type|STR) ((_COMMA|OR) (literal_type|STR|_ELLIPSIS))* _RBRACE [INT|BOOL]
set_type: (FROZENSET|SET) _LBRACKET type _RBRACKET
         | (FROZENSET|SET) [OF type_list]
tuple_type: [shape] TUPLE [(OF|WITH) [NUMBER] type (OR type)*]
          | [TUPLE] _LPAREN type (_COMMA type)* _RPAREN [PAIRS]
          | [TUPLE] _LBRACKET type (_COMMA type)* _RBRACKET
union_type: UNION _LBRACKET type (_COMMA type)* _RBRACKET 
          | type (AND type)+
          | [TUPLE] _LBRACE type (_COMMA type)* _RBRACE
          | type (_PIPE type)*
qualname.0: QUALNAME


A.2:         "a"i
AN.2:        "an"i
AND.2:       "and"i
ANOTHER.2:   "another"i
ANY.2:       "any"i
ARRAYLIKE.2: "arraylike"i | "array-like"i | "array like"i | "array_like"i | "masked array"i
ARRAY.2:     "array"i
ARRAYS.2:    "arrays"i
AS.2:        "as"i
AXES.2:      "axes"i
BOOL.2:      "bool"i | "bools"i | "boolean"i | "booleans"i
CALLABLE.2:  "callable"i | "callables"i | "function"i
CLASS.2:     "class"i
CLASSMARKER.2:":class:"
COLOR.2:     "color"i | "colors"i
COMPLEX.2:   "complex"i
DEFAULT.2:   "default"i
DICT.2:      "dict"i | "dictionary"i | "dictionaries"i
DTYPE.2:     "dtype"i
FALSE.2:     "false"i
FILELIKE.2:  "file-like"i | "filelike"i
FLOAT.2:     "float" | "floats" | "float32"i | "float64"i
FROM.2:      "from"i
FROZENSET.2: "frozenset"i
GENERATOR.2: "generator"i
IN.2:        "in"i
INSTANCE.2:  "instance"i
INT.2:       "int"| "ints"|  "integer" | "integers" | "int8" | "int16" | "int32" | "int64" | "uint8"| "uint16" | "uint32" | "uint64"
ITERABLE.2:  "iterable"i
ITERATOR.2:  "iterator"i | "iter"i
LENGTH.2:    "length"i
LIKE.2:      "like"i
LIST.2:      "list"i | "list thereof"i
MAPPING.2:   "mapping"i
MATPLOTLIB:  "matplotlib"i
MATRIX.2:    "matrix"i | "sparse-matrix"i
NDARRAY.2:   "ndarray"i | "ndarrays"i | "nd-array"i | "numpy array"i | "np.array"i | "numpy.ndarray"i
NEGATIVE.2:  "negative"i
NONE.2:      "none"i
NUMPY.2:     "numpy"i
OBJECT.2:    "object"i | "objects"i
OF.2:        "of"i
ONE.2:       "one"i
ONED.2:      "1-d"i | "1d"i | "one-dimensional"i
OPTIONAL.2:  "optional"i
OR.2:        "or"i
OVER.2:      "over"i
PAIRS.2:     "pairs"i
PATHLIKE.2:  "path-like"i | "pathlike"i
POSITIVE.2:  "positive"i | "non-negative"i | "nonnegative"i
PRIVATE.2:   "private"i
READABLE.2:  "readable"i | "readonly"i | "read-only"i
RETURNS.2:   "returns"i
SAME.2:      "same"i
SCALAR.2:     "scalar"i
SEQUENCE.2:  "sequence"i | "sequence thereof"i
SET.2:       "set"i
SHAPE.2:     "shape"i
SIZE.2:      "size"i
SPARSE.2:    "sparse"i
STR.2:       "str"i | "string"i | "strings"i | "python string"i | "python str"i
SUBCLASS.2:  "subclass"i | "subclass thereof"i
THREED.2:    "3-d"i | "3d"i | "three-dimensional"i
TO.2:        "to"i
TRUE.2:      "true"i
TUPLE.2:     "tuple"i | "2-tuple"i | "2 tuple"i | "3-tuple"i | "3 tuple"i | "4-tuple" | "4 tuple" | "tuple thereof"i
TWOD.2:      "2-d"i | "2d"i | "two-dimensional"i
TYPE.2:      "type"i
UNION.2:     "union"i
VALUE.2:     "value"i
WITH.2:      "with"i
WRITABLE.2:  "writeable"i | "writable"i
_ARROW:     "->"
_ASTERISK:  "*"
_BACKTICK:  "`"
_C_CONTIGUOUS: "C-contiguous"i
_COLON:    ":"
_COMMA:    ","
_DIM:      "0-d"i | "1-d"i | "2-d"i | "3-d"i | "1d"i | "2d"i | "3d"i
_ELLIPSIS: "..."
_EQUALS:   "="
_GRTRTHAN:  ">"
_LBRACE:   "{"
_LBRACKET:  "["
_LESSTHAN:  "<"
_LPAREN:    "("
_MINUS:     "-"
_NEWLINE:   "\n"
_PIPE:      "|"
_PLURAL:    "\\s"
_PLUS:      "+"
_PERIOD:   "."
_PRIVATE:  "private"
_RBRACE:   "}"
_RBRACKET:  "]"
_RPAREN:    ")"
_SLASH:     "/"
_STRIDED:   "strided"i
_SUCH:      "such"
_THE:       "the"
_TILDE:     "~"
_X:         "x"
NAME:      /[A-Za-z_][A-Za-z0-9_\-]*/
NUMBER:    /-?[0-9][0-9\.]*e?\-?[0-9]*/
QNAME:  /\.?[A-Za-z_][A-Za-z_0-9\-]*(\.[A-Za-z_.][A-Za-z0-9_\-]*)*/
QUALNAME:  QNAME | MATPLOTLIB AXES | MATPLOTLIB COLOR
STRINGSQ:  /\'[^\']*\'/
STRINGDQ:  /\"[^\"]*\"/
STRING:    STRINGSQ | STRINGDQ
%import common.WS
%ignore WS
%ignore _ASTERISK
%ignore _BACKTICK
%ignore _C_CONTIGUOUS
%ignore _PLURAL
%ignore _PRIVATE
%ignore _STRIDED
%ignore _SUCH
%ignore _THE
%ignore _TILDE
```

Once I get an AST out of this, I can walk it with vistors to generate the formal types. I do that with this `Normalizer` class. I can largely ignore some
ugly parts of the tree, like `shape`:

```
class Normalizer(Interpreter):
    def configure(self, module:str|None, classes: dict|None, is_param:bool):
        if module is None:
            module = ''
        x = module.find('.')
        if x >= 0:
            self._tlmodule = module[:x]  # top-level module
        else:
            self._tlmodule = module
        self._module = module
        self._classes = classes
        self._is_param = is_param

    def handle_qualname(self, name: str, imports: set) -> str:
        return name
    
    def start(self, tree) -> tuple[str, set[str]|None]:
        result = self.visit(tree.children[0])
        return result
        
    def type_list(self, tree) -> tuple[str, set[str]|None]:
        types = [] # We want to preserve order so don't use a set
        imports = set()
        literals = []
        has_none = False
        for child in tree.children:
            if isinstance(child, Tree):
                result = self._visit_tree(child)
                if result:
                    if result[0] == 'None':
                        has_none = True
                        continue
                    if result[0].startswith('Literal:'):
                        literals.append(result[0][8:])
                    else:
                        type = result[0]
                        if type not in types:
                            types.append(type)
                    if result[1]:
                        imports.update(result[1])

        if not imports:
            imports = None
        if literals:
            type = 'Literal[' + ','.join(literals) + ']'
            if type not in types:
                types.append(type)
        if has_none:
            type = 'None'
            if type not in types:
                types.append(type)
        type = '|'.join(types)
        return type, imports

    def type(self, tree)-> tuple[str, set[str]|None]:
        for child in tree.children:
            if isinstance(child, Tree):
                result = self._visit_tree(child)
                if result:
                    return result
        assert(False)

    _basic_types = {
        'ANY': 'Any',
        'INT': 'int',
        'STR' : 'str',
        'FLOAT': 'float',
        'BOOL': 'bool',
        'SCALAR': 'Scalar',
        'COMPLEX': 'complex',
        'OBJECT': 'Any',
        'PATHLIKE': 'PathLike',
        'FILELIKE': 'FileLike'
    }

    def array_type(self, tree):
        arr_types = set()
        elt_type = None
        imports = set()
        for child in tree.children:
            if isinstance(child, Token) and (child.type == 'NDARRAY' or child.type == 'NUMPY'):
                arr_types.add('NDArray')
                imports.add(('NDArray', 'numpy.typing'))
            if isinstance(child, Tree) and isinstance(child.data, Token):
                tok = child.data
                subrule = tok.value
                if subrule == 'array_kinds':
                    types, imp = self._visit_tree(child)
                    arr_types.update(types)
                    imports.update(imp)
                elif subrule == 'array_kind':
                    type, imp = self._visit_tree(child)
                    arr_types.add(type)
                    imports.update(imp)
                elif subrule == 'basic_type' or subrule == 'type_qualifier':
                    elt_type, imp = self._visit_tree(child)
                    imports.update(imp)
        if elt_type:
            if self._is_param and 'list' in arr_types:
                arr_types.add('Sequence')
                arr_types.remove('list')
                imports.add(('Sequence', 'typing'))
            return '|'.join([f'{typ}[{elt_type}]' for typ in arr_types]), imports
        else:
            return '|'.join(arr_types), imports

    def array_kinds(self, tree):
        imports = set()
        types = set()
        for child in tree.children:
            if isinstance(child, Tree):
                type, imp = self._visit_tree(child)
                imports.update(imp)
                types.add(type)
        return types, imports

    def array_kind(self, tree):
        arr_type = ''
        imports = set()
        for child in tree.children:
            if isinstance(child, Token):
                if child.type == 'NDARRAY':
                    arr_type = 'NDArray'
                    imports.add(('NDArray', 'numpy.typing'))
                elif self._is_param or child.type == 'ARRAYLIKE':
                    arr_type = 'ArrayLike'
                    imports.add(('ArrayLike', 'typing'))
                elif child.type == 'LIST':
                    arr_type = 'list'
                elif child.type == 'SEQUENCE':
                    arr_type = 'Sequence'
                    imports.add(('Sequence', 'typing'))
                else:
                    continue
                break

        if not arr_type:
            arr_type = 'NDArray'
            imports.add(('NDArray', 'numpy.typing'))

        return arr_type, imports

    def type_qualifier(self, tree):
        imports = set()
        for child in tree.children:
            if isinstance(child, Tree):
                return self._visit_tree(child)
            elif isinstance(child, Token):
                if child.type == 'QUALNAME':
                    type = self.handle_qualname(child.value, imports)
                    return type, imports
        # OF ARRAYS falls through here
        imports.add(('ArrayLike', 'numpy.typing'))
        return 'ArrayLike', imports

    def basic_type(self, tree) -> tuple[str, set[str]|None]:
        imports = set()
        for child in tree.children:
            if isinstance(child, Token):
                if child.type == 'ANY':
                    imports.add(('Any', 'typing'))
                    return 'Any', imports
                elif child.type == 'SCALAR':
                    imports.add(('Scalar', f'{self._tlmodule}._typing'))
                    return 'Scalar', imports
                elif child.type == 'PATHLIKE':
                    imports.add(('PathLike', 'os'))
                elif child.type == 'FILELIKE':
                    imports.add(('IO', 'typing'))
                    return 'IO', imports
                if child.type in self._basic_types:
                    return self._basic_types[child.type], imports

        assert(False)

    def callable_type(self, tree):
        # TODO: handle signature
        imports = set()
        imports.add(('Callable', 'typing'))
        return "Callable", imports

    def class_type(self, tree):
        cname = ''
        for child in tree.children:
            if isinstance(child, Tree):
                return self._visit_tree(child)
        assert(False)
        
    def class_specifier(self, tree):
        imp = set()
        cname = ''
        for child in tree.children:
            if isinstance(child, Token) and child.type == 'QUALNAME':
                cname = child.value
        # Now we need to normalize the name and find the imports
        x = cname.rfind('.')
        if x > 0:
            imp.add((cname[x+1:], cname[:x]))
            cname = cname[x+1:]
        elif self._classes and cname in self._classes:
            imp.add((cname, self._classes[cname]))

        return cname, imp

    def dict_type(self, tree):
        dict_type = ''
        from_type = None
        to_type = None
        imports = set()
        for child in tree.children:
            if isinstance(child, Token):
                if child.type == 'MAPPING':
                    dict_type = 'Mapping'
                    imports.add(('Mapping', 'typing'))
                elif child.type == 'DICT':
                    dict_type = 'dict'
                elif child.type == 'QUALNAME':
                    to_type = self.handle_qualname(child.value, imports)
                    if from_type is None:
                        from_type = to_type
            elif isinstance(child, Tree):
                to_type, imp = self._visit_tree(child)
                if imp:
                    imports.update(imp)
                if from_type is None:
                    from_type = to_type

        if from_type is not None:
            dict_type += f'[{from_type}, {to_type}]'

        return dict_type, imports

    
    def qualname(self, tree):
        for child in tree.children:
            if isinstance(child, Token):
                imports = set()
                return self.handle_qualname(child.value, imports), imports
            

    def filelike_type(self, tree):
        imports = set()
        imports.add(('FileLike', f'{self._tlmodule}._typing'))
        return 'FileLike', imports

    def generator_type(self, tree):
        imports = set()
        imports.add(('Generator', 'collections.abc'))
        for child in tree.children:
            if isinstance(child, Tree):
                type, imp = self._visit_tree(child)
                if type:
                    imports.update(imp)
                    return f'Generator[{type}, None, None]', imports
        return 'Generator', imports

    def iterable_type(self, tree):
        imports = set()
        imports.add(('Iterable', 'collections.abc'))
        for child in tree.children:
            if isinstance(child, Tree):
                type, imp = self._visit_tree(child)
                if type:
                    imports.update(imp)
                    return f'Iterable[{type}]', imports
        return 'Iterable', imports
    
    def iterator_type(self, tree):
        imports = set()
        imports.add(('Iterator', 'collections.abc'))
        for child in tree.children:
            if isinstance(child, Tree):
                type, imp = self._visit_tree(child)
                if type:
                    imports.update(imp)
                    return f'Iterator[{type}]', imports
        return 'Iterator', imports
    
    def literal_type(self, tree)-> tuple[str, set[str]|None]:
        imports = set()
        imports.add(('Literal', 'typing'))
        assert(len(tree.children) == 1 and isinstance(tree.children[0], Token))
        tok = tree.children[0]
        type = tok.type
        if type == 'STRING' or type == 'NUMBER':
            return f'Literal:' + tok.value, imports
        if type == 'NONE':
            return 'None', set()
        if type == 'TRUE':
            return 'Literal:True', imports
        if type == 'FALSE':
            return 'Literal:False', imports
        assert(False)

    def optional_type(self, tree):
        for child in tree.children:
            if isinstance(child, Tree):
                type, imports = self._visit_tree(child)
                type += '|None'
                return type, imports
        return 'None', set()

    def restricted_type(self, tree):
        imp = set()
        types = []
        values = []
        rtn = ''
        for child in tree.children:
            if isinstance(child, Tree):
                type, imports = self._visit_tree(child)
                imp.update(imports)
                if type.startswith('Literal:'):
                    values.append(type[8:])
                else:
                    types.append('None')
            elif isinstance(child, Token) and child.type == 'STR':
                types.append('str')
        if values:
            types.append(f'Literal[{",".join(values)}]')
            imp.add(('Literal', 'typing'))
        return '|'.join(types), imp

    def set_type(self, tree):
        set_type = None
        elt_type = None
        imports = set()
        for child in tree.children:
            if isinstance(child, Token):
                if child.type == 'SET':
                    set_type = 'set'
                elif child.type == 'FROZENSET':
                    set_type = 'frozenset'
            elif isinstance(child, Tree):
                elt_type, imports = self._visit_tree(child)

        if elt_type:
            set_type += '[' + elt_type + ']'

        return set_type, imports

    def tuple_type(self, tree):
        types = []
        imp = set()
        repeating = False
        count = 1
        has_shape = False
        for child in tree.children:
            if isinstance(child, Tree):
                type, imports = self._visit_tree(child)
                if type is None:
                    has_shape = True
                else:
                    types.append(type)
                    imp.update(imports)
            elif isinstance(child, Token) and child.type in ['OF', 'WITH']:
                repeating = True
            elif isinstance(child, Token) and child.type == 'NUMBER':
                count = int(child.value)
        if has_shape:
            return 'tuple', None
        if types:
            if repeating:
                if count > 1:
                    types = ["|".join(types)] * count
                else:
                    return f'tuple[{"|".join(types)}, ...]', imp
            
            return f'tuple[{",".join(types)}]', imp
        return 'tuple', None

    def union_type(self, tree):
        types = set()
        imports = set()
        for child in tree.children:
            if isinstance(child, Tree):
                type, imp = self._visit_tree(child)
                types.add(type)
                imports.update(imp)
        return '|'.join(types), imports
    
    def shape(self, tree):
        return None, None
    
```

There is basically one Python method for each of the grammar rules. The methods return a Python type annotation as a string, and a set of imports that 
may need to be added to the file for that annotation to be usable (e.g. if a type has `Sequence` in it, the imports need to record that we need to import
`Sequence` from `typing`). It's up to each method/node to decide whether or not it wants to walk through its children, and how to handle the result.

Let's look at a simple example, `optional_type`. The grammar rule is:

```
optional_type: OPTIONAL [_LBRACKET type _RBRACKET]
```

which says that we could have the word "optional" or something like "optional [float]". The method is:

```python
    def optional_type(self, tree):
        for child in tree.children:
            if isinstance(child, Tree):
                type, imports = self._visit_tree(child)
                type += '|None'
                return type, imports
        return 'None', set()
```

Here we walk through the children, which are either going to be terminal nodes for tokens like the left and right brackets or the word optional, or a tree
if there is a type specified (as that involves further parsing of rules). If we see a tree node for `type` we recursively visit it and get the type and
imports for that, then add '|None" on the end of the type before returning. If we find no child that is a tree, that means all we saw was 'optional' and 
we just return 'None'.

Other methods are similar; it's just the complexity that varies. 

We wrap all this in a `parse_type` function:

```python
_lark = Lark(_grammar)
_norm =  _norm = Normalizer()

    
def parse_type(s: str, modname: str|None = None, classes: dict|None = None, is_param:bool=False) -> tuple[str, dict[str, list[str]]]:
    """ Parse a type description from a docstring, returning the normalized
        type and the set of required imports, or None if no imports are needed.
    """
    try:
        tree = _lark.parse(s)
        _norm.configure(modname, classes, is_param)
        n = _norm.visit(tree)
        # Collect, dedup and sort the imports
        imps = {}
        if n[1]:
            for imp in n[1]:
                what, where = imp
                if where not in imps:
                    imps[where] = []
                imps[where].append(what)
            # Sort the imports for a module
            for where in imps.keys():
                imps[where] = sorted(imps[where])
        return n[0], imps
    except Exception as e:
        return s, {}
```

and then call that from our new `normalize_type`:

```python
def normalize_type(s: str, modname: str|None = None, classes: dict|None = None, is_param: bool = False) -> tuple[str|None, dict[str, list[str]]]:
    try:
        return parse_type(remove_shape(s), modname, classes, is_param)
    except Exception as e:
        return None, {}
```

I rewrote `is_trivial` to be more strict; the new code is below:

```python
_basic_types = {
    # Key: lower() version of type
    'any': 'Any', 
    'array': 'NDArray',
    'arraylike': 'NDArray',
    'array-like': 'NDArray',
    'bool': 'bool',
    'bools': 'bool',
    'boolean': 'bool',
    'booleans': 'bool',
    'bytearray': 'bytearray',
    'callable': 'Callable',
    'complex': 'complex',
    'dict': 'dict',
    'dictionary': 'dict',
    'dictionaries': 'dict',
    'filelike': 'FileLike',
    'file-like': 'FileLike',
    'float': 'float',
    'floats': 'float',
    'frozenset': 'frozenset',
    'int': 'int',
    'ints': 'int',
    'iterable': 'Iterable',
    'list': 'list',
    'memoryview': 'memoryview',
    'ndarray': 'np.ndarray',
    'none': 'None',
    'object': 'Any',
    'objects': 'Any',
    'pathlike': 'PathLike',
    'path-like': 'PathLike',
    'range': 'range',
    'scalar': 'Scalar',
    'sequence': 'Sequence',
    'set': 'set',
    'str': 'str',
    'string': 'str',
    'strings': 'str',
    'tuple': 'tuple',
    'tuples': 'tuple',
}

def is_trivial(s, modname: str, classes: set|dict|None = None):
    """
    Returns true if the docstring is trivially and unambiguously convertible to a 
    type annotation, and thus need not be written to the map file for further
    tweaking.

    s - the type docstring to check
    modname - the module name
    classes - a set of class names or dictionary keyed on classnames 
    """
    s = s.strip()
    sl = remove_shape(s.lower())
    if sl.endswith(" objects"):
        sl = sl[:-8]

    if sl in _basic_types:
        return True

    # Check if it's a string

    if sl and sl[0] == sl[-1] and (sl[0] == '"' or sl[0] =="'"):
        return True

    if classes:
        if s in classes or (_ident.match(s) and s.startswith(modname + '.')):
            return True

    # We have to watch out for ambiguous things like 'list of str or bool'.
    # This is just a kludge to look for both 'of' and 'or' in the type and
    # reject it.
    x1 = sl.find(' of ')
    x2 = sl.find(' or ')
    if x1 >= 0 and x2 > x1:
        return False
    
    # Handle tuples
    if sl.startswith('tuple'):
        sx = s[5:].strip()
        if not sx:
            return True
        if sx[0] in '({[' and sx[-1] in '})]':
            # TODO We should make sure there are no other occurences of these
            # A lot of this is getting to where we should go back to regexps.
            return is_trivial(sx[1:-1], modname, classes)
        
        # Strip off leading OF or WITH
        if sx.startswith ('of ') or sx.startswith('with '):
            x = sx.find(' ')
            sx = sx[x+1:].strip()
        
        # Strip off a number
        if sx and sx[0].isdigit():
            x = sx.find(' ')
            sx = sx[x+1:]

        if is_trivial(sx, modname, classes):
            return True
        
    for s1 in [s, s.replace(',', ' or ')]:
        for splitter in [' or ', '|']:
            if s1.find(splitter) > 0:
                if all([len(c.strip())==0 or is_trivial(c.strip(), modname, classes) \
                        for c in s1.split(splitter)]):
                    return True
        
    if s.find(' of ') > 0:
        # Things like sequence of int, set of str, etc
        parts = s.split(' of ')
        if len(parts) == 2 and is_trivial(parts[0], modname, None) and is_trivial(parts[1], modname, classes):
            return True
        
    # Handle restricted values in {}
    if s.startswith('{') and s.endswith('}'):
        parts = s[1:-1].split(',')
        parts = [p.strip() for p in parts]
        return all([is_trivial(p, modname, None) for p in parts])
    
    return False
```

I wasn't proud of the old one, and this one is kinda yucky too, but it is working and I haven't noticed any false positives at least. 

With these changes I was able to generate stubs for sklearn and SciPy. But I am going further, back to where I first started, and bringing in
monkeytype tracing to both validate the types I have in the map files, and to fill in gaps where there are no docstrings. I'll talk about that 
in the next post.


