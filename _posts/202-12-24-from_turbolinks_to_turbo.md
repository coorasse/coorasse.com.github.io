---
layout: post
title: "From Turbolinks to Turbo"
date: 2020-12-24 18:32:00 +0100
categories: rails
excerpt: "I was eager to start using Hotwire in a project that I thought was a perfect fit. Here I will show you what I had to do, to migrate from Turbolinks to Turbo, and keep using Webpacker as main assets bundler."
---

I was eager to start using Hotwire in a project that I thought was a perfect fit. Here I will show you what I had to do, to migrate from Turbolinks to Turbo, and keep using Webpacker as main assets bundler.

## Remove turbolinks. Add turbo.

Turbo is basically the new version of Turbolinks, so we need to remove the old npm package and add the new one:

```bash
yarn remove turbolinks
yarn add @hotwired/turbo
```

This will replace the package with the new one.

## Turbo Drive

Turbo Drive is that part of Turbo that replaces the functionalities provided before by Turbolinks.

We need to remove the previous initialization of turbolinks and initialize turbo instead.
In your `application.js` (or wherever you initialized Turbolinks), replace

```js
require('turbolinks').start();
``` with 

```js
import Turbo from "@hotwired/turbo"
```

With this, you will already have Turbo up and running.

## Replace old Turbolinks code.

The event `turbolinks:load` is now called `turbo:load`. Replace them wherever you are using them.

If you were using `data-turbolinks` attributes, they are now called `data-turbo`. You can replace them as well.

Basically you can search for `turbolinks` within your project and replace it with `turbo`.

## That's it

I started writing this post thinking "This is going to take a while. Such a guide will be useful for sure!". But it ended up being way easier than I thought 😅
In the next posts, I will show you my experiments with Hotwire and Turbo and show how I refactored the code to use the new framework. As of now, Turbo is up and running! 🥳
