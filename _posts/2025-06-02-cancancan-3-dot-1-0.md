---
layout: post
title: "CanCanCan 3.1.0"
date: 2020-03-15
categories: rails
excerpt: "A new version of CanCanCan is out!"
---

Hi all :wave:,
a new version of [CanCanCan](https://github.com/CanCanCommunity/cancancan) is out!

This is a minor release with small but important improvements.
Please read the whole [CHANGELOG](https://github.com/CanCanCommunity/cancancan/blob/develop/CHANGELOG.md).

First of all: we have a logo!
<img src="https://github.com/CanCanCommunity/cancancan/raw/develop/logo/cancancan.png" width="100">
Thanks again [Renuo AG](https://www.renuo.ch) for the big support.

The biggest improvement in this version is on how we generate the queries when you use `accessible_by` helpers. 
Instead of the distinct clause, [we now prefer an inner query](https://github.com/CanCanCommunity/cancancan/pull/605). 
This solves many issues when you have more complicated queries. 
It also allows you to use CanCanCan [even if you have JSON columns](https://github.com/CanCanCommunity/cancancan/pull/608).

We also have a better support for I18n and translation of the error messages.

Have fun!

