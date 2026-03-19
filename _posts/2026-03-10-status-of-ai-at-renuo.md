---
layout: post
title: "The last two years with AI tools: what changed, what didn't"
date: 2026-03-19
categories: ai
excerpt: "After a year of AI-assisted development at a real web agency: what genuinely helps, what's overhyped, and why software engineering matters more than ever."
---

## One year later

It's almost a year since I wrote about [our approach to AI at Renuo](https://www.renuo.ch/blog/handmade-software). Back
then, I was cautiously optimistic. Today I have a clearer picture of what actually works, what doesn't, and
what it means for the way we build software today.

Let me start with the most useful piece of advice I can give you: if you ignore a new AI tool for two or three months,
it'll likely vanish without a trace. This is already a great comfort and a considerable time saver.

[New tools keep coming out weekly](https://www.youtube.com/shorts/vGKC9LpGnOQ), and for someone who
actually needs to ship projects and deliver value, it's practically impossible to keep up with everything. Unless you're
a social media influencer whose only (respectable) job is to test new models and announce the end of the world every
other day, you simply cannot follow every development.

So here's the rule I apply: if a tool has been around for more than six months, it's worth your time and worth trying
out. Everything else? Ignore it and spend that energy on something actually useful.

I started 2026 with the firm intention of more seriously exploring AI agent-based development. Up until the end of 2025,
Cursor had been my primary tool, so I decided to explorer further.

## How we run this at Renuo

At Renuo we could enforce a single tool across the company, but we haven't, and we don't think it would be the right
call right now.

We give a lot of freedom to each person to choose and use the tools they prefer. We have people with Copilot licenses,
others on Claude, others on OpenAI. An accounting nightmare, admittedly.
But it lets us explore a wide range of options simultaneously and compare real results: if everyone were using the same
tool, we'd be missing most of the landscape.

This won't last forever. Sooner or later, shared skills and best practices will emerge, as they already have in many
other areas of the company. But at this stage, consolidating too early would mean locking in the wrong answer.

What makes decentralization work is sharing: we have dedicated Slack channels, a public feed
at [til.renuo.ch](https://til.renuo.ch), evening "beer talks" every two months, and an _all-hands_ every six weeks where
everyone shares progress on their work. The tooling is fragmented; the knowledge isn't.

## What actually helps (and what doesn't)

I've been doing web development for about 20 years, and the AI tools that emerged between 2025 and 2026 are without a
doubt the most exciting development in all that time. But excitement doesn't mean uncritical adoption. At Renuo, every
line of code still goes through the four-eyes principle (every change reviewed by at least two people) and doesn't reach
production without thorough review. AI assistance hasn't changed that, and it won't.

Here's what I've found actually useful, in concrete terms:

**Exploring options fast.** AI lets me visualize several approaches to the same problem in a very short time. In minutes
or hours, I can have three different implementations side by side, ready to compare. A year ago, I could only sketch
this on paper or imagine it in abstract terms. Today it's tangible. That said, the quality of what's produced is usually
rough, and it takes [many further iterations](https://coorasse.com/blog/iterating-with-ai/) to reach something I'd be
happy shipping. But the ability to explore different options so quickly is genuinely new.

**Navigating unfamiliar projects.** Renuo is a web agency with around 300 repositories and at least a hundred active
projects. Even after 15 years here, I don't know all of them. Being able to ask AI to walk me through a new codebase
before a meeting is genuinely useful. It doesn't replace 30 minutes with someone who's lived inside that project for
months, but it means I arrive at the introduction meetting with a real baseline.

**Bug identification.** In my experience, there's a good 50% chance AI finds the actual root cause. It often proposes
the wrong fix, but it helped pinpoint the problem. 50% is a lot.

**Where it still falls short.** The one area where modern tools consistently don't help me is making the right
engineering decisions. Over 20 years, I've developed a very particular taste for how I want things done, and AI still
has a decidedly generic aesthetic. I'm trying to adapt it to my way of working, but I think the nuances are endless, and
this may never be fully achievable. Mostly because I change my mind too often.

## Engineering matters more than ever

Despite how much models have improved (and they'll keep improving), the quality of what they produce is mediocre at
best. That's not a criticism, it's just where we are. A tool doesn't need to be great to be useful.

But it does shift what matters in a developer. If up until 2024 you could get by with modest software engineering
knowledge as long as you were a fast, reliable coder, that's no longer the case. Thankfully. How quickly you write code
is now irrelevant. What matters is knowing how to design software. That's why I'm re-reading Clean Code, The Clean
Coder, and Clean Architecture.

This is the standard I apply at Renuo, and it's the standard I'd encourage any developer to apply to themselves: being
an excellent engineer is what will give you a future in this field. But the other dimension, increasingly
important, is understanding the business side of what you're building. A blind approach to development, without caring
about the *why* behind a given feature, is what makes a person indistinguishable from an AI agent that simply, always,
does what it's told.

That distinction, between a developer who understands the problem and one who just executes the task, is where human
value now lives.

## AI as part of the process

The question I'm focused on right now, both personally and for Renuo, is not which AI tool to use, but how to integrate
AI into our existing workflows without rebuilding those workflows around it.

The goal is that AI agents assist us with specific tasks while our process stays intact. Not building processes around
AI, but making AI a natural part of the processes we already have. That's how we'll get the most out of it without
compromising on what we've always been: a software engineering company that ships quality work.
