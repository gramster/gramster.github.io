---
title: The "Tyranny" of Metrics
date: 2018-07-12T18:04:00
author: Graham Wheeler
category: Management
comments: enabled
image: /img/metrics-dashboard.jpg
---

<!-- ![Photo by Carlos Muza on Unsplash](/img/metrics-dashboard.jpg) -->

Jerry Muller recently wrote a popular book titled ["The Tyranny of Metrics"](https://amzn.to/3mKXE9z). He makes a number of good arguments for why metrics, if not used properly, can have unintended consequences. For example, the _body count_ metric that the US military optimized for in the Vietnam war caused enormous damage while losing the hearts and minds of the populace and resulting in an ignominious defeat. Muller argues that metrics are too often used as a substitute for good judgment. The book is an excellent read.

So should we be ignoring metrics? Clearly not, but we need to be cognizant of what metrics we choose and how we use them. We should also distinguish between things which can meaningfully be measured quantitatively versus things that are more suited to qualitative analyses. And we should be wary of metrics being used as an instrument of control by those far removed from the "trenches", so to speak.

Assuming that we have a problem that can meaningfully be measured in a quantitative way, we need to make sure our metrics meet a number of criteria to be useful. Here are some guidelines:

- metrics should be _actionable_: they should tell you what you should be doing next. If you can't answer the question of what you would do if a metric changed then its probably not a good metric.
- metrics should be _clearly and consistently defined_: changing the definition of a metric can invalidate all the historical record and is very costly. Do the work upfront to make sure the metric is well-defined and measuring what you want, and then don't change the definition unless you can do so retroactively. Ensure that the metric is defined and used consistently across the business.
- metrics should be _comparative_ over time (so it is useful to aggregate these over fixed periods like week-over-week or monthly - but be cognizant of seasonal effects).
- _ratios are often better than absolute values_ as they are less affected by exogenous factors. Similarly, _trends are more important than absolute values_. 
- metrics are most useful if they are _leading indicators_ so you can take action early. For example, [Work in Progress (WIP)](https://en.wikipedia.org/wiki/Work_in_process) is a leading indicator, while [cycle time](https://en.wiktionary.org/wiki/cycle_time) is a trailing indicator. Think of a highway: you can quickly tell if it is overcrowded, before you can tell how long your commute has been delayed.
- good metrics make up a _hierarchy_: your team's metrics should roll up to your larger division's metrics which should roll up to top-level business metrics.
- metrics should be _in tension_: you should try to find metrics that cannot be easily gamed without detrimentally affecting other metrics. Let's say I have a credit risk prediction model and my metric is the number of customers I predict are not credit risks but that default on their debt. I can just predict that every customer is high risk and my metric will look great, but that's bad for the business. So I need another metric that is in tension with this, such as the number of good customers I deny credit to, which must be minimized. More generally in prediction models we use the combination of [_precision_ and _recall_](https://en.wikipedia.org/wiki/Precision_and_recall).
- metrics should _capture different classes of attributes_ such as quality and throughput.
- you need to know when a deviation in a metric is a cause for concern. A good general guideline is that if a metric deviates more than two standard deviations from the mean over some defined period, you should start paying attention, and more than three standard deviations you should be alarmed.

Thanks to [Saujanya Shrivastava](https://www.linkedin.com/in/saujanya/) for many fruitful discussions over our metrics from which these guidelines emerged.


