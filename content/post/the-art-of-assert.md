---
title: The Art of Assert
date: 2008-05-02T05:28:00
author: Graham Wheeler
category: Programming
slug: the-art-of-assert
---


*"Assertions are the only reliable form of program documentation"*
(Charles Hoare)

While I wait for the next release of Live Search for Mobile, I will fill
in the time with some posts on tricks I have used in the dim and distant
past, before I became a mostly C\# programmer. I love C\#, but I really
don't like the way the C/C++ preprocessor was not included. While
preprocessors can be abused, they are also extremely useful (think of
\_\_FILE\_\_ and \_\_LINE\_\_, just for starters).

In particular, the preprocessor in C and C++ provides a very flexible
assertion mechanism that is much more useful then System.Diagnostics.
I'd like to cover some useful ways of using assertions in C and C++. Of
course if you're an Eiffel programmer, you can probably stop reading ;-)
<!-- TEASER_END -->

In the code below, I will assume the existence of a library function
**HandleAssert(char\* message**), which does appropriate assertion
handling (for example, in a GUI app it might pop up a message box,
display the message, and give a Continue/Abort/Debug choice).

Obviously, the first thing we need is a basic ASSERT macro:

```c++
#ifdef DEBUG
#define ASSERT(condition, message)     do { if (!(condition)) HandleAssert(message); } while (0)
#else
#define ASSERT(condition, message)
#endif
```

The first rule of asserts is, of course, never put them in production
code, hence the DEBUG conditional. The use of a do/while above
eliminates any possible dangling else issues that might otherwise crop
up if for some weird reason you put your ASSERTs in if statements.

The above is often the only form of ASSERT that most C/C++ programmers
encounter. But there are quite a few useful variants on the idea.
Sometimes, just an alias is already a useful distinction:

```c++
#define PRECONDITION(condition, message)     ASSERT(condition, message)
#define POSTCONDITION(condition, message)    ASSERT(condition, message)
```

It can be useful to be able to define code that only exists in
assertional builds:

```c++
#if DEBUG
#define ASSERTIONAL(code)      code
#else
#define ASSERTIONAL(code)
#endif
```

Putting all of the above in an example:

```c++
int AdvanceIndex(int index)
{
    ASSERTIONAL(int save_index = index);
    PRECONDITION(index >= 0, "Index can't be negative");
    ....

    POSTCONDITION(index > save_index, "Index must advance");
    return index;
}
```

If we have class invariants, it is useful to define these as methods in
the class that we can call from our asserts:

```c++
class foo
{
#if DEBUG
   bool invariant() { ... }
#endif
}
```

During early development, we could confine ourselves to DEBUG builds. In
this case we may want to skip over handling of bad input, etc. We can do
this safely using simplifying assumptions:

```c++
#if DEBUG
#define SIMPLIFYING_ASSUMPTION(condition,  explanation)      ASSERT(condition, explanation)
#else
#error SIMPLIFYING_ASSUMPTION not allowed in> release code
#endif
```

For example:

```c++
void Insert(node* n)
{
    PRECONDITION(n != 0 && invariant(), "Can't insert null");
    SIMPLIFYING_ASSUMPTION(find(n) == 0, "Not handling re-insertion of existing node yet");
    ...
    POSTCONDITION(find(n) != 0 && invariant(), "Node must be inserted");
}
```

Note, when writing unit tests for code that has pre- and
post-conditions, you should be striving to write tests that pass the
precondition but fail the postcondition. Thus assertions can provide
very useful test case selection guidance. Pre- and post-conditions also
tend to be more stable than the code inside methods, reduce the need to
examine the internal code, and, for the hard-core, support proving
correctness.

Sometimes we may find it useful to always fire the assert:

```c++
#define UNREACHABLE(why)      ASSERT(0, why)
```

We can have compile-time assertions on simple expressions:

```c++
#define COMPILE_TIME_CHECK(b)    extern int dummy[(b) ? 1: -1]
```

As you can see from all of this, the lowly ASSERT can be quite flexible!
