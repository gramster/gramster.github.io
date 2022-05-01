---
title: Managing Engineering and Data Science Agile Teams
date: 2018-07-03T21:53:00
author: Graham Wheeler
category: Management
comments: enabled
tags:
  - Data Science
  - Management
---

It is very common in modern software engineering organizations to use agile approaches to managing teamwork. At both Microsoft and eBay teams I have managed have used Scrum, which is a reasonably simple and effective approach that offers a number of benefits, such as timeboxing, regular deployments (not necessarily continuous but at least periodic), a buffer between the team and unplanned work, an iterative continuous improvement process through retrospectives, and metrics that can quickly show whether the team is on track or not.


Data science work does not fit quite as well into the Scrum approach. I've heard of people advocating for its use, and even at my current team we initially tried to use Scrum for data science, but there are significant challenges. In particular, I like my Scrum teams to break work down to user stories to a size where the effort involved is under two days (ideally closer to half a day). Yes, we use story points, but once the team is calibrated fairly well its still easy to aim for this. Trying to do this for data science work is much harder, especially when it is research work in building new models which is very open-ended.


The approach I have taken with my team is an interesting hybrid that seems to be working quite well and is worth sharing.
<!-- TEASER_END -->
My team is actually three teams - a data science team, and two engineering teams. The engineering teams are responsible for the services that consume the models produced by the data science team (although these services add a lot of functionality beyond the models - for example, we have delivery estimate models that predict seller handling time and shipping transit time in business days, but the services implement logic to convert these to calendar days, taking into account everything from seller and carrier working days to severe weather events and postal strikes).


The engineering teams follow a pretty standard Scrum process. As we typically like to do production deployments at the end of sprints and don't want to do those on Fridays, we end sprints on Wednesdays; we'll usually do a deployment on a Tuesday afternoon then do sprint retrospectives and planning on Wednesday (we do sprint demos on a different cadence as those have a broader audience). 


Each team has an agile lead. During engineering team sprint planning meetings, the data science agile lead will attend. He may have some asks of the engineering team, like pushing a new model to production. These asks may go to the backlog but a new model is usually something we want to release fast so it will typically make it straight into the next sprint. Sometimes the engineering team will have asks of the data science team. In this case the data science lead will assign a member of the data science team to this task and they will be "on loan" for the sprint to the engineering team; they will attend stand-ups and other meetings and the work item they are tasked with will be tracked as just another "engineering" work item in the sprint.


The rest of the time the data science team has available is dedicated to exploratory work building new models or the like. This work is tracked on a separate Kanban board by the data science team. Tasks on that board can be updated at any time by the team members and they do a weekly team meeting as well to update the Kanban board collectively. This allows the team to have more time flxibility for their tasks but we pay attention to how long work items on the board remain in "in-progress" state and if that starts being too long we will break the task down further or reprioritize it. We use work-in-progress limits on this board too to avoid too much multitasking.


We've been using this approach for about a year now and so far it has been working well - certainly much better than when we tried to use Scrum which was frustrating for both the team and for me. Give it a try!

