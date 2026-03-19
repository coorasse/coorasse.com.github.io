---
layout: post
title: "Onlylogs - The idea behind it"
date: 2025-09-19
categories: rails
mermaid: true
excerpt: "At Renuo we are working on onlylogs, a new gem and SaaS that will help you manage your logs, the way you want it."
---

## What's the matter with logs?

The problem with logs is how bloated and/or expensive each existing solution out there seems to be.

When working with Ruby on Rails, I like the fact that I can start a project from scratch and I don't need any external
dependency.

This has been made even more true with the introduction of solid gems: solid_queue, solid_cache, solid_cable and
ensuring that sqlite is a good default also for production.

New libraries are now tackling two points:

* errors monitoring: solid_errors
* performance monitoring: rails_pulse

Logs management is the missing piece of the puzzle, and this is the context where onlylogs has been built.

There's no built-in solution to check your logs in Rails, so we decided it was time to build one.

## Existing solutions

Splunk, Elasticsearch, Logstash, Kibana, Grafana Loki, and then again Datadata, Appsignal.
All those are great enterprise solutions, that don't fit the needs of a new, starting project.

## The principles behind onlylogs

The tool we wanted is `grep`. `grep`...but on a web interface.
We are developers: we know regular expressions, and we can do everything we want with them.
Also, we like **files**. Files are powerful and simple, so in a starting project they are **simply enough**.
That's why onlylogs will work with the `production.log` file you already have out-of-the-box.
We don't require a particular format, we don't require an external dependency, we don't even require you to setup a
database.

I believe we will elaborate further in the future about this concept and we will be able to provide even more features,
with a small sqlite database next to the log files, but that's not in focus today.

## The gem

Today's focus is giving you a performant, memory efficient, and secure, way of looking at your logs directly within your
web application.

We are well aware that if your app doesn't start, you also are not able to read your logs, but remember: your logs are
where they have always been: on your disk. This means you can still `ssh` into your server and check them manually if
needed.

The [onlylogs gem](https://rubygems.org/gems/onlylogs) gives you the possibility of reading your logs without sshing into the server: your only limit will
be your CPU speed and Disk Space.

If you want to store more logs: buy more disk space. This will result in a much longer retention period (you decide!) and much cheaper.

Your limits are decided by you: retention, disk space, etc...

## The SaaS

Next to the gem, we also built https://onlylogs.io. 

La piattaforma espone dei log drain endpoint ai quali inviare i propri log.
Da un certo punto di vista, è molto simile a soluzioni già esistenti, ma l'architettura alla base è davvero semplice.
https://onlylogs.io infatti, una volta ricevuto del testo, senza nessun tipo di requirement sulla formattazione, 
lo salva su disco, di nuovo, in semplici file di testo.
E di nuovo, la piattaforma utilizza la stessa gemma onlylogs per visualizzare, fare live streaming e permettere le ricerche sui file.
In quanto l'architettura è così semplice, è anche possibile fare download dei file raw per ulteriori analisi.

Chiaramente, se si ha la gemma già installata, è davvero molto semplice iniziare ad inviare i propri log ad https://onlylogs.io oltre a salvarli in locale.

Per istruzioni su come installare la gemma, ed utilizzare il visualizzatore, fate riferimento al README ufficiale.

Per quanto riguarda, invece, l'utilizzo di https://onlylogs.io per fare streaming dei vostri log, trovate le istruzioni sul sito web.

Qui di seguito anche due video che mostrano come installare onlylogs nelle due modalità.
