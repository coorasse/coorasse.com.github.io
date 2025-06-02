---
layout: page
title: Bootstrap as a Service
permalink: /bootstrap_as_a_service/
---

When [the #nobuild approach to Rails](https://www.youtube.com/watch?v=iqXjGiQ_D-A) was announced, 
I started wondering how I could still use Bootstrap. 

I wrote a [blog post]({% post_url 2022-01-12-rails_bootstrap_importmaps %}) on how you can use Bootstrap 
with Rails 7+ with importmaps and without nodejs,
but this still requires `dartsass-sprockets` to compile the SCSS files.

Most of the times I don't need to customize Bootstrap too much, 
so I realized [Bootstrap as a Service](https://bootstrap.coorasse.com/) for fun.

Check it out and let me know what you think!
