---
title: Creating Type Stubs for Scientific Python (Part 1)
date: 2022-08-25T21:23:00
author: Graham Wheeler
category: Programming
comments: enabled
---

This is part 1 of what will be two or three posts. In this post, I cover building a basic type stub generator; in the next post, I'll get into handling
scientific Python packages specifically.

## Why I Care About Python Type Stubs

One of the teams I manage in my day job is the [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) team, who build the Python language server for Visual Studio and Visual Studio Code. Pylance is built on top of the statis type checker [pyright](https://github.com/Microsoft/pyright), but where pyright focuses on finding errors, Pylance is focused on providing a great editor experience (as well as finding errors, but the editor experience is paramount).

In order to provide great completions when you hit '.' after some expression, we need to know the type of the object to the left of '.'. If it is a string (`str`), for example, we know we can offer completions like `find` or `rfind`. So types are super-important to providing a great experience.

Pyright has a state-of-the-art type inference engine for Python, that computes a 'reverse computation graph' from the point you hit '.', in order to try to evaluate what the expression type is. But, Python being a dynamic language, this can be difficult or impossible in many cases. Bear in mind this code is being evaluated _statically_, it isn't being executed. There are many APIs in [pandas](https://pandas.pydata.org/), for example, that may return a Series or a Dataframe based on the type of data that was loaded earlier from a CSV file; pyright does not know what this will be at run time so cannot necessarily infer exactly which type to provide completions for. There are also cases where objects are constructed in loops or comprehensions where analysis is difficult or at least unbounded, and we need to provide completions fast. One of the best ways to help pyright speed up its analysis or resolve ambiguous or intractable situations is to use type annotations. While type annotations are not necessarily that common in end user code, they are becoming more prevalent in packaged libraries. But if a library has no annotations, another option is to use _type stub files_, which have a similar structure but contain just the annotated types and signatures for the library. Pylance ships with some type stubs for common libraries, but you can also install your own in a `typings` directory in your workspace.

## Lessons Learned Stubbing pandas and matplotlib

One of the areas we focus on in Visual Studio Code is data science and scientific Python. So we would like to provide a good experience for the packages popular in that domain, many of which don't have stubs or inline annotations. An eraly focus of ours was `pandas`, and we created the most complete stubs to date for that library, and I am happy to say that with a lot of help and support from pandas core developer Dr. Irv Lustig, we managed to get the pandas code devs to take over maintenance of these type stubs, which can be found now at [pandas-dev/pandas-stubs: Public type stubs for pandas (github.com)](https://github.com/pandas-dev/pandas-stubs). I was the main author behind these stubs, as this is a 'spare time' project as the Pylance team is focused on developing Pylance. After I handed off pandas, I decided to tackle matplotlib, and in early September we shipped the [resulting stubs](https://github.com/microsoft/python-type-stubs/tree/main/matplotlib), which, while not complete, are much more comprehensive than the ones we bundled before.

While doing these two libraries, I noticed a similarity in how the docstrings were formatted. It turns out there is a convention for docstrings in scientific Python, namely [numpydoc](https://numpydoc.readthedocs.io/en/latest/format.html). Furthermore, in many cases these docstrings include type information. Not as formally as in Python typing, but formally enough to be a useful source of typing information. So I decided to generalize what I had been doing to allow me to address a broader set of packages.

The pandas stubs were created completely by hand, from reading the docstrings. For matplotlib, I automated more of the process; in fact, I used multiple stages:

- I used pyright to generate initial stubs without types

- I used [MonkeyType](https://monkeytype.readthedocs.io/en/stable/index.html) to run all the examples, and then applied the resulting types from the traces to the pyright-generated stubs

- I wrote a utulity to parse the docstrings and augment the stubs from the last stage with those types, where I could make sense of them

- I did a manual cleanup pass (which was still quite a large effort, but the prior steps probably saved me about 70% of the work compared to doing it all manually)

In retrospect, I don't think doing the MonkeyType step bought me as much as I expected, as it produced a number of false positives I had to clean up (for example, parameters that were always `None` in the examples). Plus I had to patch MonkeyType to allow it to be able to _patch existing stubs_; it had the ability to patch source .py files or generate stubs, not not augment stubs. And MonkeyType crashed a lot, so I had to work around that (in some cases I just swallowed exceptions so that it wouldn't give up on a whole file but would apply partial updates). But the most useful part of using MonkeyType, and having to dive into its source code, was I learned about [LibCST](https://libcst.readthedocs.io/en/latest/), the concrete syntax tree library it is built on top of. This is a very useful library if you want to patch Python files.

## Starting Over without MonkeyType

While I don't want to preclude augmenting stubs with MonkeyType traces, I thought it woudl be useful to create a utility that could generate stubs for packages using numpydoc-format docstrings only. It would always be possible to add more types based on execution traces later (and I may cover that in a later blog post). Given I would use LibCST to insert the type annotations, it made sense to try use that to generate the stubs end-to-end, removing the need for the first step of generating unannotated stubs with pyright. I thought the process should more or less be as follows (ignoring the docstrings/types for now:

- replace all function bodies with '...'
- replace the right hand side of any assignment statements at the top level or within classes but not within functions with '...' (but take note of the type of the right-hand side; this could be used to annotate the line later). These are class attributes, or in some cases, method aliases (e.g. in matplotlib there is something like a `setcolors` method in some class that is followed by `setcolor=setcolors` to alias it)
- (optionally) replace all default parameter value assignments with `=...`. I say optionally, as for Pylance we would actually like to keep these; we will show the stub to users as the method signature when hovering in the editor, and this is useful information
- remove any top-level code that is not a simple assignment (handled in previous step), import statement, class or function definition
- (To be done later) - get the types from the docstrings and annotate parameters, return values and attributes where possible. Take special note of default value assignments of `None` and augment the types with `None` as an union option, as this is not always called out explicitly in the docstrings.
- Remove all docstrings
- Save the new file as a stub
- Format them with Black



## Let's Do This! Basic Stubs without Types using LibCST

LibCST is reasonably easy to understand, although can take some experimentation to figure out how to get it to do what you want. It basically allows you to parse some Python code into a concrete syntax tree (CST), which is similar to an abstract syntax tree (AST) except it records things like whitespace that would be discarded by an AST. Because the CST retains all information about the source, it can be used to regenerate an exact copy of the input, while an AST would lose some information, especially around formatting. For stub generation the distinction isn't that big a deal, but LibCST works for our purposes and so is what I will use.

Once the Python code is parsed into a CST, you can apply visitors to the tree to modify it. LibCST walks the tree, and calls method in your visitor class upon entry and exit from each node:

- for the entry methods you usually would just set some flags or counters to tell that you were in a class or function, so that other visitors have more context when they are deciding what to do. You can also short-circuit the tree traversal in an entry method, and tell LibCST to not recurse through any of the child nodes (this will be useful when we do things like replace function bodies with `...`).

- the exit methods are the main place you would modify the tree; you can create a modified version of the node and replace that instead of the original.

Once the tree walking is complete, you can either apply further visitors, or you can generate code form the (possibly modified) CST.



### Removing Default Parameter Values

Here's a simple example of a transformer to replace parameter default argument values with `...`. I guard this with a `strip_defaults` flag because, as I mentioned, while many stubs do use this form, for Pylance we actually want to keep the default values intact:

```python
import libcst as cst


class StubbingTransformer(cst.CSTTransformer):

    def __init__(self, strip_defaults=False):
        self.strip_defaults = strip_defaults

    def leave_Param(self, original_node: cst.Param, updated_node: cst.Param) -> cst.CSTNode:
        """ Remove default value if present and replace with ..."""
        if self.strip_defaults and original_node.default is not None:
            return updated_node.with_changes(default=cst.parse_expression('...'))
        return updated_node
```

Note that I want to replace the value with the CST node corresponding to `...`; rather than try to construct that it is easier to just use the helper `cst.parse_expression` to construct it for me from the source string `'...'`.

### Replacing Function Bodies with `...`

This is another easy one, similar to the above:

```python
    def leave_FunctionDef(self, original_node: cst.FunctionDef, updated_node: cst.FunctionDef) -> cst.CSTNode:
        return updated_node.with_changes(body=cst.parse_statement('...'))
```

### Driver Function for Stubbing a Module's Files

To use this, I want a driver function that I can pass a module name and have it patch the source files for that module, but write the results as `.pyi` files. I'll follow the Pylance convention and put the stubs in a `typings` folder:

```python
import glob
import importlib
import os


def patch_source(source: str, strip_defaults: bool = False) -> str|None:
    try:
        cstree = cst.parse_module(source)
    except Exception as e:
        return None
    try:
        patcher = StubbingTransformer(strip_defaults=strip_defaults)
        modified = cstree.visit(patcher)
    except:  # Exception as e:
        # Note: I know that e is undefined below; this actually lets me
        # successfully see the stack trace from the original excception
        # as traceback.print_exc() was not working for me.
        print(f"Failed to patch file: {e}")
        return None
    return modified.code


def stub_module(m: str, strip_defaults: bool = False):
    try:
        mod = importlib.import_module(m)
        print(f"Imported module {m} for patching")
    except Exception:
        print(f"Could not import module {m} for patching")
        return
    file = inspect.getfile(mod)
    if file.endswith("/__init__.py"):
        # Get the parent directory and all the files in that directory
        folder = file[:-12]
        files = glob.glob(folder + "/*.py")
    else:
        files = [file]

    for file in files:
        try:
            with open(file) as f:
                source = f.read()
        except Exception as e:
            print(f"Failed to read {file}: {e}")
            continue

        modified = patch_source(source)
        if modified is None:
            print(f"Failed to parse {file}: {e}")
            continue

        target = "typings/" + file[file.find("/site-packages/") + 15 :] + "i"
        folder = target[: target.rfind("/")]
        os.makedirs(folder, exist_ok=True)
        with open(target, "w") as f:
            f.write(modified)
        print(f"Stubbed file {file}")


```

There's a bit of a kludge in the one exception block, which helps me with debugging issues in LibCST. Don't ask.

### Dealing with Top-Level or Class-Level Assignment Statements

In order to deal with more complex cases, it can be useful to see the tree that LibCST creates for various constructs. There are some helper methods we can use; we have already used `parse_expression`. Let's see what happens for the statement `x=1+2`:

```python
import libcst as cst
cst.parse_statement('x=1+2')
```

```
SimpleStatementLine(
    body=[
        Assign(
            targets=[
                AssignTarget(
                    target=Name(
                        value='x',
                        lpar=[],
                        rpar=[],
                    ),
                    whitespace_before_equal=SimpleWhitespace(
                        value='',
                    ),
                    whitespace_after_equal=SimpleWhitespace(
                        value='',
                    ),
                ),
            ],
            value=BinaryOperation(
                left=Integer(
                    value='1',
                    lpar=[],
                    rpar=[],
                ),
                operator=Add(
                    whitespace_before=SimpleWhitespace(
                        value='',
                    ),
                    whitespace_after=SimpleWhitespace(
                        value='',
                    ),
                ),
                right=Integer(
                    value='2',
                    lpar=[],
                    rpar=[],
                ),
                lpar=[],
                rpar=[],
            ),
            semicolon=MaybeSentinel.DEFAULT,
        ),
    ],
    leading_lines=[],
    trailing_whitespace=TrailingWhitespace(
        whitespace=SimpleWhitespace(
            value='',
        ),
        comment=None,
        newline=Newline(
            value=None,
        ),
    ),
)

```

So, we can replace the RHS of assignments with `...` with:

```python
    def leave_Assign(self, original_node: cst.Assign, updated_node: cst.Assign) -> cst.CSTNode:
        return updated_node.with_changes(value=cst.parse_statement('...'))

```

Something to watch out for though: the statement `x: int = 3` actually generates an `AnnAssign` node, not an `Assign` node. So we need to deal with it too:

```python
    def leave_AnnAssign(self, original_node: cst.Assign, updated_node: cst.Assign) -> cst.CSTNode:
        return updated_node.with_changes(value=cst.parse_expression('...'))
 
```

### Removing Other Statements

Now let's turn to removing unnecessary content from the stub. We want to retain import statements, top-level assignments, class definitions and function definitions. It turns out that import statements and assignments are wrapped in a `SimpleStatementLine` node, and are included in a `body` property which is a list. Class and function definitions similarly go in a `body` list of a module node. So we can modify those two nodes to have body lists that only include the nodes we want to keep:

```python
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
   
```

This isn't perfect; for example, we will drop imports like:

```python
try:
    import pandas
except ImportError:
    pass
```

We could add a visitor method to visit all Import nodes, and if they are not under a top-level SimpleStatementLine node then collect them and inject them later; for now we'll defer on that.

We could also remove functions and classes that are private; i.e. have names that start with a single underscore. The danger there is that they may actually be referenced by public classes and methods (as parameter or return types, or default parameter values). For now we will keep them. We can look at removing them later.

### Removing Nested Classes and Functions

Currently we are not removing nested classes or functions, but conventionally they are removed in stubs. We can handle this by adding nesting level counters to class and function definitions, and then using those to decide how to handle the same nodes. We only want to retain classes at level 0 (top-level classes), and functions at level 0 (top-level functions), or at level 1 if we are at class level 1 (methods).

I don't know how to completely get rid of the nested functions and classes in an elegant way, so for now I just replace them with `...`.

```python
class StubbingTransformer(cst.CSTTransformer):
    def __init__(self, strip_defaults=False):
        self.strip_defaults = strip_defaults
        self.in_class_count = 0
        self.in_function_count = 0
        
    ...
    def visit_ClassDef(self, node: cst.ClassDef) -> bool:
        self.in_class_count += 1
        # No point recursing if we are at nested function level
        return self.in_class_count == 1

    def leave_ClassDef(self, original_node: cst.ClassDef, updated_node: cst.ClassDef) -> cst.CSTNode:
        self.in_class_count -= 1
        if self.in_class_count == 0:
            return updated_node
        else:
            # Nested class; return ...
            return cst.parse_statement('...')

    def visit_FunctionDef(self, node: cst.FunctionDef) -> bool:
        self.in_function_count += 1
        # No point recursing if we are at nested function level
        return self.in_function_count == 1

    def leave_FunctionDef(
        self, original_node: cst.FunctionDef, updated_node: cst.FunctionDef
    ) -> cst.CSTNode:
        """Remove function bodies"""
        self.in_function_count -= 1  
        if self.in_function_count == 0 or \
            (self.in_function_count == 1 and self.in_class_count == 1):
            return updated_node.with_changes(body=cst.parse_statement("..."))
        else:
            # Nested function; return ...
            return cst.parse_statement('...')
    
```


### Preserving Class and Method Aliases

There's really little difference between `x=y` and `x=True` as far as LibCST is concerned; they both represent the right-hand side with a `Value` node. So we can collect the names of functions within a class, and if we see an assignment of a class attribute where the right-hand side refers to a previously defined method, we can retain the value. We can do something similar at global scope for classes.

We add sets in the constructor to keep track of the method and class names:

```python
    def __init__(self, strip_defaults=False):
        self.strip_defaults = strip_defaults
        self.in_class_count = 0
        self.in_function_count = 0
        self.method_names = set()
        self.class_names = set()
```

When entering class or function definition nodes, we record the names:

```python
    def visit_ClassDef(self, node: cst.ClassDef) -> bool:
        # Record the names of top-level classes
        if self.in_class_count == 0:
            self.class_names.add(node.name.value)

        self.in_class_count += 1
        # No point recursing if we are at nested function level
        return self.in_class_count == 1
        
    def visit_FunctionDef(self, node: cst.FunctionDef) -> bool:
        if self.in_class_count == 1 and self.in_function_count == 0:
            # Record the method name
            self.method_names.add(node.name.value)
        self.in_function_count += 1
        # No point recursing if we are at nested function level
        return self.in_function_count == 1        
```

We also need to clear the set of method names when exiting a class:

```python
    def leave_ClassDef(self, original_node: cst.ClassDef, updated_node: cst.ClassDef) -> cst.CSTNode:
        self.in_class_count -= 1
        if self.in_class_count == 0:
            # Clear the method name set
            self.method_names = set()
            return updated_node
        else:
            # Nested class; return ...
            return cst.parse_statement('...')
```

Now we can change the assignment handler to retain the value if it is a method or class alias:

```python

    def get_assign_value(self, node: cst.Assign) -> cst.CSTNode:
        # See if this is an alias, in which case we want to
        # preserve the value; else we set the new value to ...
        new_value = None
        if isinstance(node.value, cst.Name) and \
           self.in_function_count == 0:
            check = set()
            if self.in_class_count == 0: # Top-level
                check = self.class_names
            elif self.in_class_count == 1: # Class level
                check = self.method_names
            if node.value.value in check:
                new_value = node.value
        if new_value is None:
            new_value = cst.parse_expression("...")  
        return new_value
        
    def leave_Assign(
        self, original_node: cst.Assign, updated_node: cst.Assign
    ) -> cst.CSTNode:
        return updated_node.with_changes(\
            value=self.get_assign_value(updated_node))
```

### Inferring Type Information from Assignment Statements

Of course, these stubs aren't adding any real value as they have no type annotations that weren't present in the original code. So now let's look at adding more types.


First, let's just infer types from the right-hand-side values. The code below will do that for assignment statements, converting them from `Assign` nodes to `AnnAssign` nodes:

```python
    @staticmethod
    def get_value_type(node: cst.CSTNode) -> str|None:
        typ: str|None= None
        if isinstance(node, cst.Name) and node.value in [
            "True",
            "False",
        ]:
            typ = "bool"
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
            }.items():
                if isinstance(node, k):
                    typ = v
                    break
        return typ

    def leave_Assign(
        self, original_node: cst.Assign, updated_node: cst.Assign
    ) -> cst.CSTNode:
        typ = StubbingTransformer.get_value_type(original_node.value)
        # Make sure the assignment was not to a tuple before
        # changing to AnnAssign
        if typ is not None and len(original_node.targets) == 1:
            return cst.AnnAssign(target=original_node.targets[0].target,
                annotation=cst.Annotation(annotation=cst.Name(typ)),
                value=cst.parse_expression("..."))
        else:
            return updated_node.with_changes(\
                value=self.get_assign_value(updated_node))

```

We can update our handling of parameters to also do type inference from default values:

```python
    def leave_Param(
        self, original_node: cst.Param, updated_node: cst.Param
    ) -> cst.CSTNode:
        annotation = original_node.annotation   
        if original_node.annotation is None and original_node.default is not None:
            typ = StubbingTransformer.get_value_type(original_node.default)
            if typ is not None:
                annotation = cst.Annotation(annotation=cst.Name(typ))

        default = original_node.default
        """Remove default values, replace with ..."""
        if self.strip_defaults and default is not None:
            default=cst.parse_expression("...")

        return updated_node.with_changes(default=default, annotation=annotation)

```

We actually only want to use these inferred types if the docstrings don't give us the types, but this shows how we can do it, and is useful for arbitrary Python code. In the next post I'll look at how we can get type information from the numpydoc-format docstrings and add that to the stubs.









