---
layout: post
title: "Ruby On Rails: Bootstrap 5 and importmaps without nodejs"
date: 2022-01-12 21:01:00 +0100
categories: rails
excerpt: "How can you integrate Bootstrap in a Rails application without NodeJS"
---

## Our goal: remove nodejs

As many other people in the Rails community, I started setting up brand new Rails 7 projects, and I need to re-learn, at least partially, how to bundle the assets and distribute them.

I never fell in love with TailwindCSS, and therefore I usually setup my Rails apps to use Bootstrap as default.

But what I really like about Rails 7, is the idea of being able to get rid of not only webpack, but of nodejs entirely. The new importmaps feature is really appealing to me and I'd like to use it as long as I don't need to bundle my javascript.

I have to say that `esbuild` does already a pretty cool job compared to `webpack` to simplify our lives, and make the process faster, but as long as I don't need bundling, I'd like to not have a package.json file and being dependent on nodejs for my Rails app.

A pure and simple sprockets + importmaps app with no Foreman, no `bin/dev`, no `yarn build --watch` stuff.

Bootstrap is made of two parts: CSS and javascript. So I want to use importmaps for the javascript part and rely on sprockets for the CSS compilation from SCSS.

## Rails default

By default, Rails provides an option `--css=bootstrap`,
but with my great surprise, this option adds both `jsbundling-rails`, `cssbundling-rails`, a `package.json` and `esbuild`.

**Not as expected. Not what I want.**

# How to configure Rails and Bootstrap without nodejs

Default is not what I want, but I can still reach the goal and here I'll explain how:

**Stick with just `rails new myapp`**
This will setup exactly the tools I want: `sprockets` and `importmaps`. 
It will also setup automatically for me stimulus and turbo, which is great because I use them most of the time anyway.

**Add `bootstrap` gem** and the gem `dartsass-sprockets` in the Gemfile. 
This will allow us to compile bootstrap from SCSS without node.

You can simply import Bootstrap styles in `app/assets/stylesheets/application.scss`:

```scss
// here your custom bootstrap variables...
@import "bootstrap";
```

That's it for the CSS part. Running `rails assets:precompile` will generate what you want.

**For the javascript part** we need to do three things:

* Precompile the bootstrap.min.js that comes with the gem, by adding to `config/initializers/assets.rb`

```ruby
Rails.application.config.assets.precompile += %w( bootstrap.min.js popper.js )
```

* pin the compiled asset in `config/importmap.rb`:

```ruby
pin "popper", to: 'popper.js', preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true
```

* Include bootstrap in your `app/javascript/application.js`:

```js
import "popper"
import "bootstrap"
```

I prefer this approach rather than pinning a CDN because we avoid diverging versions of Bootstrap.

## Conclusion

This is all you need to have Bootstrap fully working on Rails without using node.

If you like this guide you can [follow me on Twitter](https://twitter.com/coorasse).
