---
title: Unit Tests that Don't Suck
slug: unit-tests-that-dont-suck
date: 2021-06-26T16:19:57
tags:
  - Programming
  - Testing
category: 
link: 
description: 
---

## tl;dr

This is a long post. I think its valuable reading, but I can also sum up my recommendations as:

_Build good but narrow APIs that are the public contracts for your code. Focus your tests on these. Don't bother testing at the level of methods, classes, etc, except insofar as these represent the public APIs, with the exception of complex algorithms that may need particular attention._

## Introduction

This post is based on a talk I gave to my team in an effort to establish a common approach to thinking about unit tests. The existing code base we had suffered from a number of problems relating to how tests were being written; despite good intentions, it can be easy to do testing badly. In particular, here are some of the things I observed:

- a massive overuse of dependency injection: pretty much all dependencies of all classes were being set up using DI. I believe this was related to the next point about the overuse of mocks. DI is certainly useful, especially when wiring up a high-level architecture, but it does not need to be used for everything;
- a massive overuse of mocking. This was the main problem I observed. I went so far as to write a simple Python script to generate some metrics around this, and in the most egregious cases I found tests that had over 60 mocked classes being created. At that level it is very difficult to even know what is being tested; are you just testing that your mocks exhibit the behavior you specified in the mocks? What real behavior is being tested?
- an overuse of classes. This was TypeScript code; top-level functions are allowed, and can be encapsulated in namespaces; you don't have to put everything in a class;
- treating unit tests as testing units of code rather than units of behavior. This meant a lot more internal implementation details were being exposed than necessary, and there was too much "unit testing" and not enough functional and integration testing;
- there was disagreement within the team about which of the above were problematic and a lack of consistency in approach that was unproductive.

As a result, writing tests was hard, code reviews could be acrimonious, the design was overcomplicated and opaque, and the tests were not actually even testing that much. This was despite the fact that a lot of effort was going in to writing tests. It was clear that we needed to do better, and that meant starting out with a common approach and more education for junior developers who would otherwise just emulate existing patterns and practices. To address this, I started by giving a talk to the entire team on better testing practices. The below is my opinion, but I can attest to the fact that after these practices were adopted in a large new piece of code, we got major improvements in ease of test writing, effectiveness of tests, comprehensibility of tests, and overall architecture.

<!-- TEASER_END -->

## Why Test?

If we want to sustain velocity, including in the face of changing requirements, we need to:

- avoid regressions and wasting time on finding bugs in existing code - so we need to be able to detect regressions quickly and pinpoints their origin accurately
- not accrue large amounts of technical debt, but instead keep our code simple to understand and modify. We need confidence that continuous refactoring is not going to break functionality, and tests can provide that confidence.
   
In addition:

- tests are *executable documentation* - if you want to know what the code does in a certain case, the tests can tell you
- a passing test suite can reduce the effort required in code review, as reviewers don't have to manually verify that code behaves as intended (corollary: as a reviewer, you should demand quality tests)
- tests exercise our APIs and help to ensure that they are well-designed and usable

So tests are clearly good, but...

## Tales from the Trenches

*It's morning: you change a few lines of code and a bunch of tests break. None of the tests are catching an actual bug in the code you changed; they just made assumptions about implementation (implicit contracts) that were broken. But you have to try to understand, check and fix each one anyway, and the band-aids you apply make the tests even less readable and less useful. It's now the end of the day and you still haven't added new tests or validated your actual change. You were mostly just 'fixing' broken tests.*

*You get an alert that the CI build failed. You go take a look. Several tests failed. You recognize the first two as flaky tests once again flaking out. The next one is an old test that has broken for the first time in a long time. 'Great!', you think, 'We caught a bug!' But you look at the test and can't for the life of you figure out what it's actually doing. The last one takes a while to understand, but once you do you realize it wasn't even testing any code, it was just 'testing' the mocks. You disable all four tests and move on.*

What value were these tests?

The tests in these scenarios had the opposite effect of what good tests should have:

- they were unclear in intent, and drained productivity and morale as they were hard to read and understand
- they did not help to improve the design of the system
- they failed to find any actual bugs
- they were brittle - they failed as a result of an unrelated change that didn't introduce new bugs
- they were unreliable

Such tests are all cost with no benefit. Much of this post is about recognize good vs bad tests to avoid these kinds of situations. But we'll start with an overview of testing in general with a particular focus on unit tests.

## Unit Tests

A unit test is an automated test (of a *system under test* or SUT) that:

- verifies a single unit (of behavior or of code; see schools)
- executes fast
- and in isolation from other tests (so you can run/rerun tests individually in any order)

Isolation is achieved with the help of *test doubles*.

Unit tests have a 3-part structure:   

- *Arrange*: bring the system under test (SUT) and its dependencies to a desired state
- *Act*: call methods on the SUT, pass the prepared dependencies, and capture the output value (if any).
- *Assert*: verify the outcome (the return value, the final state of the SUT and its collaborators, or the methods the SUT called on those collaborators).

I prefer the alternative nomenclature: *Given/When/Then*, as this form encourages a more declarative writing style and thus tests that are clearer to read.

If you're doing test-driven development (TDD) you may write the *Then* section first and then figure out the first two sections.

Unit tests can be good or bad. We've seen examples above already of bad tests. The differences are pretty clear:

| Good Tests | Bad Tests |
|---|---|
| Automatic | Manual (not always bad) |
| Reliable | Flaky |
| Fast to execute | Slow to execute |
| Clear (useful as documentation) | Hard to understand |
| Tests high-value code | Tests the wrong things |
| Sensitive to regressions | Poor at catching regressions |
| Resilient to changes in implementation | Brittle |
| Clearly identifies the failure | Hard to interpret |
| Easy to write | Difficult to write |
| Easy to set up | Hard to set up |

## Test Doubles

We often want to isolate behavior when testing, and/or may need to replace slow, stateful systems like databases; we do this with *test doubles*, which are fake dependencies such as:

- *stubs* that emulate calls the SUT makes to dependencies to get input data. Types of stubs include *dummies* which just return hard-coded values, and *fakes* which replace dependencies that don't yet exist (common in TDD), or high-fidelity simulations of systems that are broadly used (e.g. file system or database fakes);
- *mocks* which emulate calls the SUT makes to dependencies that change the state of those dependencies.

Mocking libraries are used to create both mocks and stubs, so when we "mock" something we may be doing either of these; it's an unfortunate overload of the term.

Bertrand Meyer, the creator of the Eiffel language, came up with the *Command-Query Separation Principle*, that can help with having a cleaner design and has an impact on testing: *Every method should be either a command (with side effects on state but returning no value) or a query (with no side effects, returning a value), but not both.*

In other words, clearly separate methods that change state from those that don't. You can then use queries in many situations and in different orders with little risk, and focus much more of your attention on getting commands correct. Of course, every rule has exceptions: e.g. stack.Pop() which changes state and returns a value.

In the context of Test Doubles: a method in a test double can be a stub or a mock but shouldn't be both.

## Types of Test Validation

There are three main types of unit test checks used in the Assert/Then part of the test:

- output-based or *functional testing* where you feed an input to the SUT and check the output it produces;
- *state-based testing* that verifies the public state of the system after an operation is completed ("what" checks);
- *interaction-based testing*, where you use mocks to verify communications between the system under test and its collaborators ("how" checks).

Functional testing is the easiest and cleanest. Interaction-based tests are the most brittle, as we often change how our code works, and interaction tests are typically tied to implementation. Interaction tests often rely on mocks, so when the code changes the mock often must be changed too. It's good practice to think about how you can avoid interaction tests and instead convert them to functional or state-based tests.

## Test-Driven Development (TDD)

You can't really talk about testing without talking about TDD. 

The typical workflow for TDD is:

- Outer loop: write one or more failing acceptance tests for the feature that is about to be developed. These tests may take multiple checkins before they pass, and are excluded from CI until they are passing. Use stubs for dependencies that don’t yet exist; the stub will evolve as the desired API for that dependency emerges;
- Inner loop: write one or more failing unit tests or integration tests for the class/method or other unit that is about to be written, then write the code to make that pass. All unit tests must be passing before checking in, and are run as part of CI.

Reliable acceptance tests are often hard to write after the fact. Doing them upfront helps make sure we create testable software.

Acceptance tests ideally exercise the system end-to-end without directly calling internal code or making assumptions about implementation - so they go through user interface, public API, web service, etc. Even better is if these tests include the process by which the system is built and deployed. So if possible, you want a check in/merge to master to:

- check out latest version, compile and unit test the code
- integrate and package the system, and perform a production-like deployment into a realistic environment
- exercise the system through its external access points to run the acceptance tests for completed functionality

TDD can be a useful practice because:

- writing tests first is a *design activity* that clarifies acceptance criteria, encourages loose coupling, adds an executable specification of the code's purpose, all while adding to the regression suite and letting us know when we have done enough (YAGNI);
- developers are often bad at writing sufficient quality tests after the code is written and apparently working, and writing them afterwards accrues only a few of the above benefits.

In addition,  for the very first acceptance test, we must have implemented a whole automated build, deploy, and test cycle. This is a lot of work to do before we can even see our first test fail, but deploying and testing right from the start of a project forces the team to understand how their system fits into the world. It flushes out the “unknown unknown” technical and organizational risks so they can be addressed while there’s still time (see also )

That said, TDD is time-consuming, can lead to an overabundance of tests that outlive their usefulness, and doesn't protect you from most of the pitfalls 
outlined in this post. Persoanlly, I occasionally find it useful but more as an incremental/iterative design activity to clarify my thinking; I don't 
do it a lot and I usually clean up or get rid of a lot of the tests I produce afterwards.

## The Testing Schools - Classic vs "London"

When mocking libraries first became popular, a school of thought arose in which it was considered good practice to mock all dependencies. The idea behind this is that this provides the best isolation of the SUT; any test failures are clearly going to be because something is wrong in the SUT and not because of a change in a dependency. This approach came out of a community of testers in London, and became known as the "London School" or "Mockist school".

There is certainly value in this approach, but like a lot of good ideas, it can be taken to extremes and become counter-productive. It works best in conjunction with well-designed and decoupled, modular code; if the code is not clean, then following this testing approach can end up being obscurist. Unfortunately, this has become one of those tech "holy wars" where each side will tend to assume you use the other school's approach badly in order to argue why it's wrong. I do believe though that it is easier to fall into the “use badly” bucket when using Mockist approach:

- extensive use of doubles that get out of sync with real implementation can have a significant maintenance cost;
- over-reliance on mocking can mean more integration tests are needed to trust your code;
- code must be designed for test doubles (support for injection etc). This is not free (although in some cases can improve design).

The London School came out of the TDD world and reflects that; if you are doing TDD you need to use mocks at least in the cases where the real objects don’t yet exist. I think it causes way more problems when testing is done after the fact.

Some of the differences are:

| Classic School | London School |
|---|---|
| Mock shared mutable dependencies | Mock all mutable dependencies |
| Use CI w/small code deltas and good error messages to find faults | Test small amounts of isolated code to pinpoint faults |
| Prefer state-based tests | Okay with interaction-based tests |
| More 'black-box' | Prone to coupling tests to implementation details |
| Tests are 'higher-level' and better able to detect design problems | Rely more on acceptance tests for design feedback |

(Shared dependencies here are shared between tests, so the kind of dependencies that may prevent tests from being run in parallel or out-of-order; a typical example would be a database or file system).

My advice is: if you're doing TDD/BDD you'll likely need to adopt a more Mockist approach but if not, the Classical School can let you test more surface with less  scaffolding and make it easier to avoid brittle tests (e.g. from an over-reliance on mocking).

It's worth noting this quote from Andrew Trenk and Dillon Bly of Google:

*“One lesson we learned the hard way is the danger of over-using mocking frameworks. \[At first\] they seemed like a hammer fit for every nail - they made it very easy to write highly focused tests against isolated pieces of code without having to worry about how to construct the dependencies of the code. …Several years and countless tests later … we began to realize the costs of such tests. Though these tests were easy to write, we suffered greatly given that they required constant effort to maintain while rarely finding bugs. \[Now\] many engineers avoid mocking frameworks in favor of writing more realistic tests.”*

So, when should you use mocks? Aside from mutable shared dependencies, other possible good use cases are:

- replacing slow components
- replacing non-deterministic components
- replacing resource-intensive components or hard to initialize/configure components
- generating stub values that would be hard to create with the real code
- in TDD, stubbing dependencies that don't yet exist (but consider replacing these later with real code)

Otherwise IMO you should prefer using real code as much as possible.

The rest of this post will dive into the other attributes of good tests with some advice on how to achieve these.

## Unit Tests should test Units of Behavior

The main mistake I have seen made with unit tests has been thinking that unit tests should be testing "units of code" (whether that be functions, methods or classes). That is a slippery slope that is going to lead to a very brittle architecture and a lot of confusion and debate about what should and shouldn't be tested. If you wrote tests for every function you would be writing an order of magnitude more test code than product code, and the maintenance burden would be immense.

Instead, you want to test "units of behavior", and in particular, units of behavior as expressed in things like user stories or their first level breakdown into steps. What is a meaningful action that can be taken using the public API of a system? That is a good abstraction for thinking about a test. You want to avoid thinking about implementation (the "how"), and thinking instead about functionality (the "what").

## Tests should be Reliable

When we say that tests should be reliable, we mean that they should not be flaky, and should not produce false positives (test fails but the code is correct - often this may be because the test is using interaction testing that is tied to the implementation and the implementation changed) or false negatives (code is wrong but test passes anyway; this may be because the code was changed and introduced bugs but the test was poorly constructed and is not checking the right things).

To improve reliability, strive for functional or state-based checks, check boundary conditions, reduce the use of mocks, especially of volatile components, *but* do use mocks in the case of nondeterministic or unreliable dependencies to avoid tests being flaky.

## Tests should be Fast and Automated

If tests run automatically and run fast they will be run often, and the converse is also true, so we want to make sure the cost of running tests is low. You can profile you code or use domain knowledge to identify slow components that should be replaced by test doubles. If you are testing async code and have to do that by polling for a state change, make sure to use short polling intervals or - better - find a way to use a callback instead to signal completion.

If the tests are not fast, and can’t be made fast, be more selective about when they are executed. For example, Google classifies tests as unit, integration or end-to-end, but separately also classifies them as small, medium or large depending on resources required, including time:

| Size | Constraints | When Run | Ratio |
|---|---|---|---|
| Small | Single thread, no blocking I/O (can use fakes) | Before commits | 80% |
| Medium | Single host (127.0.0.1 only) | Before merges | 15% |
| Large | Unconstrained | As part of CI releases | 5% |


## Tests should prioritize High-Value Code

   We can classify code according to complexity (e.g. cyclomatic) and number of dependencies:
   
   | Complexity | Few Dependencies | Many Dependencies |
   |---|---|---|
   | Low Complexity | Trivial code | Controllers/orchestrators |
   | High Complexity | Domain model, algorithms, etc | Big balls of mud |
	
- *Trivial code* may not need or be worth testing. It’s certainly low priority.
- *Controllers/orchestrators* are best tested with integration and end-to-end tests, rather than creating complex test setups with lots of mocks.
- *Domain model code and complex algorithms* are where we get the most bang for the buck with unit tests; focus on these first.
- *[Big balls of mud](https://en.wikipedia.org/wiki/Big_ball_of_mud)* should be refactored/separated into controller code and domain code if possible, as a higher priority task than test coverage. 

## Tests should be Sensitive to Regressions

The best way to do this is to test as much real code as possible, and make sure to test for boundary conditions/edge cases. This is where overuse of mocks will hurt you, especially if you change the code being mocked and the mocks are not changed to reflect that. 

Edge cases are inputs that the specification for your function allows but that might be tricky to handle or unexpected in practice. They’re both a common source of bugs in and of themselves, but are also useful in testing because they can span the expected range of behavior of a function. Some common edge cases with ints are 0, -1, 1, minint, and maxint, while for arrays, you should try null, the empty array, an array of length 1, and a very long array, for example.

A good practice when fixing regression bugs that were not caught by tests is to add new tests to make sure a similar regression will be caught in the future.

## Tests should be Resistant to Change

*Brittle tests* - tests that break due to unrelated code changes - have a high maintenance cost and low value. We should be able to change underlying implementations - e.g. due to automated refactoring - without tests starting to fail. If they do fail, that means we have changed the behavior, or we have written the tests at the wrong level of abstraction, or the tests are too reliant on implementation details. In the latter two cases we should improve the quality of the tests.

Only when *changing existing behavior* should we expect that some tests might break and need to be updated. Bug fixes should not clearly break existing tests unless the tests themselves were wrong. Nor should adding new features (unless we are doing TDD and these are red/green tests).

If your tests do break when you change or add code that should not affect existing behavior, as yourself [what can you learn?](https://www.youtube.com/watch?v=h4XMoHhireY).

Interaction tests are frequently brittle as they rely on implementation details, so they are best avoided. As much as possible, tests should behave like regular clients of the code and [only call public APIs](https://testing.googleblog.com/2015/01/testing-on-toilet-prefer-testing-public.html), which are explicit contracts and are generally much more stable than implementations; if a test breaks when calling the public API that guarantees users of the code would be similarly affected.

What constitutes a 'public API' is context-dependent. Helper classes may have public methods but if used only in limited places may not count. APIs of libraries that are to be used by 3rd parties definitely count. There is a gray area in between that often depends on org structure.

Related to the above, you want to test at architectural "seams" (public APIs being examples). Your system is made up of components that interact with each other, and those interaction points are the natural boundaries at which you should be thinking about testing. Avoid the temptation to create artificial seams just for testing purposes, as this can cause technical debt and architectural brittleness later, as well as simply muddying the real structure of the system. If you are making private members public just to support testing you are probably doing something wrong.

## Tests should Clearly Identify Issues

When a test fails, you now have the challenge of figuring out what the failure means. The more information you can get at this point the better. You would also like to pinpoint the part of the code responsible, and this is why the London school like to use mocks extensively, the theory being that the amount of code under test is smaller and so it is easier to find an issue (however, there are significant trade-offs as I hope the earlier discussion has made clear).

The biggest help here is going to be using good assertion libraries that provide clear failure messages.  Examples in the Java world are Hamcrest, AssertJ, or Google Truth. Avoid simplistic `assertTrue`/`assertFalse` asserts which are low-information. For example:

```
// Google Truth (https://github.com/google/truth)

assertThat(names).contains("Graham");
assertThat(first.endDate()).isNotEqualTo(second.endDate()));
```

is much better than:

```
// jUnit
assertTrue(names.contains("Graham")); // "expected TRUE" is not very useful
assertFalse(first.endDate().equals(second.endDate()));
```

For example, below is an error message generated by Google Truth; you can see it provides extensive context around the failure:

```
assertThat(projectsByTeam())
 .valuesForKey("corelibs")
 .containsExactly("guava", "dagger", "truth", "auto", "caliper");

value of : projectsByTeam().valuesForKey(corelibs)
missing (1) : truth

───

expected : \[guava, dagger, truth, auto, caliper\]
but was : \[guava, auto, dagger, caliper\]
multimap was: {corelibs\=\[guava, auto, dagger, caliper\]}
 at com.google.common.truth.example.DemoTest.testTruth(DemoTest.java:71)
```

You should also consider overriding classes used in test data with subclasses that then override the `toString()` (or equivalent) method to give a more meaningful 'expected...but got' assertion message. For example, if we create `Date` objects to specify a range, we could use an override `NamedDate` class so we can name the dates, like "start date" and "end date". Some mock libraries allow named mocks that achieve a similar effect.

While I have generally argued against using interaction assertions, they do provide more behavioral information than state or functional assertions, so if you have to use them put them first so that they are more likely the failures that get reported, as they may give you a better clue as to what went wrong.

Another good way to help narrow down the code that caused a test failure is to make sure you do do frequent small pushes to source control so when a test fails unexpectedly you can at worst know that there is not a lot of code to inspect to find the problem and at best just quickly revert, which may be more efficient than spending time trying to debug the problem.

Clarity and efficiency is lost not only when the reason for a failure is not obvious, but also when the reason for the test is not obvious, so name tests clearly in a way that describes the point of each test case and its differences from the other test cases (e.g. use [testdox](https://en.wikipedia.org/wiki/TestDox)). As tests are typically discovered and called via reflection there is little cost to having long meaningful names that describe what is being tested and the expected behavior.

## Tests should be Easy to Read

For tests to be easy to read, they should be as self-contained as possible. Aim for clarity and brevity. If you use arrange or assert test helpers (which can help with brevity), name them very clearly so that their purpose is clear just from the name; the test body should be readable in isolation without having to understand a bunch of helper methods unless those are very clear from their names. Avoid handling exceptions unless you are specifically testing that an exception is being thrown. Try to keep the code path linear, with no loops or branches; you may be able to achieve the same effect with parameterized tests or through using multiple tests, and a failure will be more clear while still improving readability.

Avoid hidden globals or singletons; these are semi-hidden dependencies that may be non-obvious to the reader. You can inject these instead to make them local and explicit. Similarly, test suite setup code is hidden context and best avoided; if you use it, use it to construct stateless objects. Be particularly careful about not having your test suite setup code be the code that creates the state that you are later testing for.

If you make use of literal constants, assign them to variables with names that express their intent before using them.

As tests have no tests themselves, clarity is key! It's okay to duplicate code in service of readability. [https://testing.googleblog.com/2019/12/testing-on-toilet-tests-too-dry-make.html](https://testing.googleblog.com/2019/12/testing-on-toilet-tests-too-dry-make.html)

Focus on the most important assertions; if you assert on all the resulting state you may obscure the true purpose of the test, or fail due to an unrelated issue.  Assert helpers, if used, should be focused on single relevant facts and not bundle up multiple different checks.

## Tests should be Easy to Write

If a feature is difficult to test, ask why. Are you testing at the right level of abstraction? Should the test be written at a higher/lower level? Should the code itself be refactored to be easier to test?

While generally you want to avoid relying on test helpers as they can obscure the code, an exception is test data helpers. These can be [written in a style that is declarative](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.18.4710&rep=rep1&type=pdf) and easy to read so they are not only convenient but help with readability.

## Measuring the Quality of our Tests

 We've spoken about the importance of having tests that are sensitive to regressions; i.e. do the tests actually find bugs? How can we measure this? One way might be:

- How many bugs did we find through tests?
- How many bugs made it to production?
- What’s the ratio of the above two numbers?

This is a bit too squishy, especially the first number, unless we are diligent about tracking, and it is not easy at all to automate. In addition, its a lagging metric so we can only tell how good the tests *have been*, not how good they *are*. We need something better.

*Mutation testing* involves modifying our code small ways, using mutation operators that mimic programming errors. Each mutated version is called a mutant. If a previously passing test fails when run against a mutant, we say it *kills* the mutant; if no test kills the mutant, the mutant *survives*. The *mutation index* is the percentage of mutants killed by the test suite.

Apart from tracking the mutation index as a general metric for test quality, we get additional value from mutation testing. Tests that kill no mutants are weak tests and could be improved or removed. Code with surviving mutants is weakly tested code and new tests can be added to kill more of the mutants. 

That said, there are limitations. Some mutations still produce same result as unmutated code and will never be caught. The bugs introduced by mutation are small and localized (often inverting conditionals) and may not be reflective of real-world human error. 

Mutation testing is computationally expensive, but good tools only mutate the code covered by a test and it is now quite practical; still, you should expect an order of magnitude or more increase in the time for a test run. There are a number of tools available (see [https://en.wikipedia.org/wiki/Mutation\_testing](https://en.wikipedia.org/wiki/Mutation_testing)). The most mature of these is [Stryker](https://stryker-mutator.io/).    

## Code Reviews

Questions to ask when reviewing code:

- are there tests? If not, why not? Except in exceptional cases there should always be tests;
- read the tests first and again at the end. If properly done, they should help you understand the code you are going to review. They should also give you confidence that the code you are reviewing works so you don't have to verify that yourself
- can I understand the tests? Are they clear in intent? Are they testing the right things?
- do the tests match the requirements for the user story?
- is the changed code covered by tests? Are there areas missing coverage? Should that be addressed?
- do the tests meet the other attributes described in this post? Can they be improved?


## Further Reading

Probably the most important read is from James Coplien:

- [Why Most Unit Testing is Waste](https://rbcs-us.com/documents/Why-Most-Unit-Testing-is-Waste.pdf)

I think its a farily extreme position, but largely accurate in describing the net effect of bad testing practices.

Other useful reads:

- Flaky tests at Google and how we mitigate them - Google - [https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html) (lots more good stuff at [https://testing.googleblog.com/](https://testing.googleblog.com/))
- Mocks aren't Stubs - Martin Fowler - [https://martinfowler.com/articles/mocksArentStubs.html](https://martinfowler.com/articles/mocksArentStubs.html) - good discussion of the two schools and other topics
- Mocking is a Code Smell – Eric Elliott - [https://medium.com/javascript-scene/mocking-is-a-code-smell-944a70c90a6a](https://medium.com/javascript-scene/mocking-is-a-code-smell-944a70c90a6a) – some JS specific advice
- (Google) Automated Testing Playbook - [https://github.com/mbland/automated-testing-playbook](https://github.com/mbland/automated-testing-playbook)
- ["Unit Testing: Principles, Practices and Patterns"](https://amzn.to/3FJT6rm), Vladimir Khorikov - an excellent classical school book that covers many of the topics in this post
- ["Growing Object-Oriented Software, Guided by Tests"](https://amzn.to/3eCAXzY), Steve Freeman and Nat Pryce - a good book on London-school style TDD



