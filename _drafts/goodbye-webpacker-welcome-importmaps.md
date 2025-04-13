A simple guide to switch from Webpacker to Importmaps.

## Introduction

It was 2018 when I wrote a guide that helped literally **thousands** of people in moving from Sprockets to Webpacker.
Now that [Webpacker is deprecated](https://github.com/rails/webpacker#webpacker-has-been-retired-), is time to move forward.

In this guide, I'll show a real step-by-step migration from Webpacker to Importmaps of a Rails application.
We won't have any jsbundling at the end: so no esbuild, no webpack, no nodejs, no external bundling process.
You can still decide to use jsbundling-rails, but is not covered in this guide.

## Prerequisites

Check your package.json file: all your dependencies should be available from CDN or as Ruby Gems.
Also, we won't have javascript bundling anymore, this means no Typescript. If your application uses typescript or other js libraries that require a precompilation step, look into a guide to migrate from webpacker to jsbundling-rails before using importmaps.

Also, your app will not run on Internet Explorer.

You must have Sprockets >= 4, so if you need to, update it!

## Install importmaps-rails

`bundle add importmap-rails` will add [the Gem](https://github.com/rails/importmap-rails) to your app.

Always read the gem README file to know how to set it up properly, but in short you'll need to run:

`bin/rails importmap:install`

Read careful the output of the command, because you might have to do some manual steps.

You will now have the following:

* `javascript_importmap_tags` included in your layout. This will generate the importmaps tag into your pages head. You don't know what this does? Please [look at the video from DHH](https://youtu.be/PtxZvFnL2i0?t=435).

*  `app/javascript/application.js` is your new entry point where you'll define which JS packages you want to use in the page. Of course you can have multiple of these if you need a different set of JS libraries in different parts of your application. `javascript_importmap_tags` will include `application.js` by default, but you can always specify the entry point: `javascript_importmap_tags('dashboard.js')` and define a new `app/javascript/dashboard.js`. Generally speaking: all your JS entrypoints that were previously in the `packs` folder, will now be moved into `app/javascript/*.js` files.

* a new `vendor/javascript` folder where you will download all JS libraries that you don't want to refer to from a CDN.

* `config/importmap.rb` the new importmaps configuration file where all available libraries will be defined. This is where **available libraries** are defined. `app/javascript/application.js` defines the libraries to actually use. This means that in this file you will always include all the libraries, while the single JS entrypoints will define which ones to actually use.

* `bin/importmap` some helpful commands. Check the library README for more information.

## Hello importmaps

Let's start by starting the app, writing `console.log('hello importmaps')` in application.js, and refresh the page in the browser to see if the setup is ok.

## Rails UJS and Turbo

Let's start by moving rails-ujs and turbo. You actually should not need rails-ujs anymore, but is probable that you still have it around.

Remove them from package.json with `yarn remove @hotwired/turbo-rails @rails/ujs`

## Stimulus controllers


1. Install the `stimulus-rails` gem in your Gemfile.

2. I assume you had all your stimulus controllers inside a `controllers` folder. Move that folder to `/app/javascript/controllers` and update the `index.js` file, that was previously written to support webpacker, to:

```js
import { application } from "controllers/application"

import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

double check on [stimulus page](https://github.com/hotwired/stimulus-rails#with-import-map) for the installation instructions using importmaps.

2. Add `import 'controllers'` into your new `application.js` file.

3. Add an `app/javascript/controllers/application.js` file with:

```js
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
```

4. Update your importmap.rb configuration with:
```ruby
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
```

You can now safely remove the unnecessary npm packages from package.json:

`yarn remove @hotwired/stimulus @hotwired/stimulus-webpack-helpers`.

## CSS

If you were previously using Webpacker also to compile your CSS resources (I hope you did), we will need to switch back using `sprockets` and `sassc-rails`.

Add an `app/assets/stylesheets/application.scss` and move all your (S)CSS files in this folder, updating references.

## Migrate bootstrap
I wrote on [a specific article how to configure Bootstrap with importmaps](https://dev.to/coorasse/rails-7-bootstrap-5-and-importmaps-without-nodejs-4g8). Step by step, you'll have to:

* remove Bootstrap from package.json: `yarn remove bootstrap @popperjs/core`
* `bundle add boostrap` will include the latest bootstrap version from a rubygem.

## Fonts

Also for fonts, we will simply rely on sprockets. So they can all be moved inside `/app/assets/fonts` and all references need to be updated. If you were referencing the fonts in CSS using `url`, you need to replace it with `font-url`.

## Font Awesome

If you were previously using an npm package, I suggest you to upgrade to FontAwesome 6 and use either a CDN for the free version or [a kit](https://fontawesome.com/docs/web/setup/use-kit) for the PRO version.

## Images

Move images from the webpacker folder to `app/assets/images` and replace `image_pack_tag 'media/images/<path>'` in your views with `image_tag '<path>'`
