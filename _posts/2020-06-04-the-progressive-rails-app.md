---
layout: post
title: "The Progressive Rails App"
date: 2020-06-04
categories: rails
excerpt: "A step by step tutorial to create a Progressive Web App with Ruby on Rails and Webpacker"
---

#### A step by step tutorial to create a Progressive Web App with Ruby on Rails and Webpacker

If you Google for this topic you will find [different tutorials](https://www.google.com/search?q=progressive+web+app+rails) on how to realise a Progressive Web App with Rails. I was really not happy with any of the solutions I found so far: I wanted a solution purely based on Webpack.

In this article, I will suggest to you how to realise a Progressive Web App (PWA) using the latest Webpacker and the latest Rails release.

This technique uses just a simple npm package and supports any [Modern Rails Application](https://medium.com/rubyinside/a-modern-web-application-with-rails-da3deb48014c) and therefore we will define a new concept: "The Progressive Rails App" (PRA).
The solution I provide does not perform any workaround by serving the service workers through a controller or by skipping the Webpack pipeline.

If you already know what a PWA is, you can skip directly to [Getting Started](#getting-started), otherwise, the next chapter is meant for you.

# What is a PWA (for Rails developers)

There are some points that must be fulfilled, in order to consider our application a PWA. Once all these points are respected, the users will be able to install the app on their mobile devices as a standard app. In addition, it will be soon possible to publish your PWA on the Play Store or install it on Desktop.

Let's see these points one by one, from the Rails developer point of view:

### It loads instantly, also offline

A service worker must be registered in our application so that it can be loaded also in the absence of an internet connection. This tutorial focuses a lot on how to configure a Service Worker for our Rails app, and we'll do it using Webpacker.

### Site is served over HTTPS

For a Rails developer, it simply means to have `config.force_ssl = true` inside the `production.rb` configuration. Your website will be served over https, and this requirement will be fulfilled.

### Responsive design

Many frontend libraries are available to simplify the design of a responsive application. In a previous article, I explained why you should get rid of Sprockets and [use Webpack also for CSS](https://medium.com/@coorasse/goodbye-sprockets-welcome-webpacker-3-0-ff877fb8fa79) and other static resources. If you did that, you can simply use an npm package to install Bootstrap or Bulma to help you designing your frontend.

### manifest.json

This file, that you'll have to place inside the public folder, will contain all the information necessary to install the app on the device of your users.

# Getting Started

Start a brand new Rails app (or use you existing one):

```bash
rails new progressive-rails-app --skip-sprockets
```

and enable HTTPS for production in your `config/environments/production.rb` file.
This is important because one of the requirements for a PWA is that it runs on https.
If you are starting from scratch, here are some commands to create some content. We add a simple CRUD for Posts, to start testing our application:

```bash
bundle exec rails g scaffold Post title:string content:text
bundle exec rails db:migrate
```

And point the root page to hit:

```ruby
root 'posts#index'
```

You can also add some seeds:

```ruby
5.times do |i|
  Post.create(title: "Post #{i}", content: 'A lot of stuff')
end
```

Now that we have some data and a working application, we can start adding what it takes for it to be considered a PWA.

### manifest.json

If you debug your app from the Google Chrome Console you'll see that your app doesn't contain a Manifest

![Brand new Rails app without any manifest.json](https://dev-to-uploads.s3.amazonaws.com/i/5bujtx4rfwuo53y8shcs.png)

Let's create a Manifest file. This is the starting point of every PWA.

Add the following to your `application.html.erb` template:
```html
<link rel="manifest" href="/manifest.json">
```

And create a `manifest.json` in the `public` folder of the project. The manifest should contain all the minimal entries to avoid warnings in the browser. Here is an example:

```json
# manifest.json example
{
  "short_name": "PWA",
  "name": "Progressive Web App",
  "icons": [
    {
      "src": "/icons/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "start_url": "/",
  "background_color": "#3367D6",
  "display": "standalone",
  "scope": "/",
  "theme_color": "#3367D6"
}
```

You can generate all the icons you need from https://www.favicon-generator.org/ and place them in a `public/icons` folder.

### Adapting the Webpacker configuration

At the time of writing this article, the provided, default, configuration of [Webpacker doesn't allow us to write a Progressive Web App](https://github.com/rails/webpacker/issues/448).

The main reason is that Service Workers should reside in the public folder, while all the resources are compiled inside the public/packs folder.

We need to customize the Webpacker configuration in order to:
* keep compiling all resources in the public/packs folder;
* compile Service Workers in the public folder without appending an hash at the end of the name;
* make webpack-dev-server listen to the whole public folder to Hot Reload your content also when Service Workers change.

I adapted the `@rails/webpacker` configuration and published it as an [npm package](https://www.npmjs.com/package/webpacker-pwa). This package will allow you to use all the power of Webpack and advanced features like Hot Module Reloading, while developing your Progressive Rails App. It tackles exactly the points listed above.

Install the `webpacker-pwa` npm package with `yarn add webpacker-pwa` and change `config/webpack/environment.js` to the following:

```js
const { resolve } = require('path');
const { config, environment, Environment } = require('@rails/webpacker');
const WebpackerPwa = require('webpacker-pwa');
new WebpackerPwa(config, environment);
module.exports = environment;
```

and add the following to `webpacker.json`:

```json
service_workers_entry_path: service_workers
```

`service_workers` is the folder where we will write our service worker(s).
If you configured it correctly, when running `bin/webpack` you should see:

```
webpacker-pwa is configured but no service workers are available.
```

## The first Service Worker

Create a `service-worker.js` in the `app/javascript/service_workers` folder with the following debug content:

```
self.addEventListener('install', function(event) {
    console.log('Service Worker installing.');
});

self.addEventListener('activate', function(event) {
    console.log('Service Worker activated.');
});
self.addEventListener('fetch', function(event) {
    console.log('Service Worker fetching.');
});
```

and register it in `application.js` with:

```js
window.addEventListener('load', () => {
  navigator.serviceWorker.register('/service-worker.js').then(registration => {
    console.log('ServiceWorker registered: ', registration);

    var serviceWorker;
    if (registration.installing) {
      serviceWorker = registration.installing;
      console.log('Service worker installing.');
    } else if (registration.waiting) {
      serviceWorker = registration.waiting;
      console.log('Service worker installed & waiting.');
    } else if (registration.active) {
      serviceWorker = registration.active;
      console.log('Service worker active.');
    }
  }).catch(registrationError => {
    console.log('Service worker registration failed: ', registrationError);
  });
});
```

this will allow us to see if the service worker is working correctly.

Note: do not use webpack-dev-server for now. Is not yet working, but we will get there!

Note 2: add `public/service-worker.js*` to `.gitignore`. You shouldn't push this file directly. It's compiled by webpack.

If you did everything correctly you will see the following in the Chrome DevTools console:
![Service Worker installed](https://dev-to-uploads.s3.amazonaws.com/i/vv7vpw5j5gyn7w7um4g4.png)

And on the Chrome console, you should see:

```
ServiceWorker registered:  
Service Worker installing.
Service worker installing.
Service Worker activating.
```

Now, when we deploy our application, and SSL is available, you should see the install icon on the browser.
![Install icon on Chrome Browser](https://dev-to-uploads.s3.amazonaws.com/i/880qwh8shlhjdqlc1poz.png)

If you want to test this locally, you can use a service like ngrok.com, just run `ngrok http 3000` on the root folder of your project.

If you receive a "Blocked host" error, you can disable this check temporarily by setting `config.hosts = nil` inside `config/environments/development.rb`.

## Your Progressive Rails App

And that's it! You have your first Service Worker running and your app is now officially a Progressive Rails App! 🎉

![Installed app](https://dev-to-uploads.s3.amazonaws.com/i/drh2pq2i4tmg0u4wlz1d.png)
<figcaption>This looks already pretty cool since it allows you to install the application on your device</figcaption>

From now on, you can follow any Progressive Web App tutorial to start implementing your services, and if you are already experienced with Service Workers, you can start coding as you are used to. But here I will give you some more details about how to get the maximum out of your Progressive Rails App and implement a couple of features that you might need most of the times.

# Push Notifications
That's why you are here, right? You want to send push notifications to your users as well, right? You also want your app to show the super annoying message "Wants to send you push notifications" and start annoying your customers, right? Let's do it!

## Ask for permission

Start by asking for permissions, without this, you cannot send any notification. You should do that after registering your service worker, so change the code we wrote in application.js as follows:

```js
navigator.serviceWorker.register('/service-worker.js').then(registration => {
  console.log('ServiceWorker registered: ', registration);

  // all code from before

  window.Notification.requestPermission().then(permission => {    
    if(permission !== 'granted'){
      throw new Error('Permission not granted for Notification');
    }
  });
});
```

You should handle all the cases properly, but this is out of scope for this tutorial, please refer to [this one](https://medium.com/izettle-engineering/beginners-guide-to-web-push-notifications-using-service-workers-cb3474a17679) for example, to get some more details about how/when to ask for permissions and how to manage all possible responses from the user.


![Ask for permission](https://dev-to-uploads.s3.amazonaws.com/i/9mo5fw60eiwo4ybzlrcs.png)
<figcaption>Also our app can annoy users with Push Notifications.</figcaption>

Click "Allow" to give notifications permissions and if you refresh the page, it won't ask you anymore, since it already obtained permission before.

## Subscribe to notification service

You need to generate a pair of public/private keys to send notifications. Again follow the article linked above for the details about why.

```bash
yarn global add web-push
web-push generate-vapid-keys
```

Now change our `service-worker.js` to subscribe to the push manager and react to push notifications:

```js
function urlB64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (var i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

self.addEventListener('install', function(event) {
  console.log('Service Worker installing.');
});

self.addEventListener('activate', async function(event) {
  console.log('Service Worker activated.');
  try {
    const applicationServerKey = urlB64ToUint8Array('<YOUR_PUBLIC_KEY_HERE>')
    const options = { applicationServerKey, userVisibleOnly: true }
    const subscription = await self.registration.pushManager.subscribe(options)
    console.log(JSON.stringify(subscription))
  } catch (err) {
    console.log('Error', err)
  }
});
self.addEventListener('fetch', function(event) {
  console.log('Service Worker fetching.');
});
self.addEventListener('push', function(event) {
  console.log('[Service Worker] Push Received.');
  console.log(`[Service Worker] Push had this data: "${event.data.text()}"`);

  const title = 'A nice title';
  const options = {
    body: event.data.text(),
    icon: 'images/icon.png',
    badge: 'images/badge.png'
  };

  event.waitUntil(self.registration.showNotification(title, options));
});
```

Every time you change your service worker you need to manually unregister it from the Chrome Application tab in Developers' tools, and refresh the page.

You should see in the Browser console:
```json
{ "endpoint":"https://fcm.googleapis.com/fcm/send/...",
  "expirationTime":null,
  "keys":{
    "p256dh":"...",
    "auth":"..." }
}
```

Save them. You'll need them later.

From the DevTools, from the same window where you unregister your service worker, you can now send a test push notification.

![Send test push notification](https://dev-to-uploads.s3.amazonaws.com/i/yw285bxajbehbk4gjdoo.png)

## Send notifications from ruby

In short, that's easy. Add the `webpush` gem and use the following:

```ruby
require 'webpush'

Webpush.payload_send(
    message: 'Hello from ruby',
    endpoint: <ENDPOINT-HERE>,
    p256dh: <P256DH-HERE>,
    auth: <AUTH-HERE>,
    vapid: {
        subject: 'Hello from ruby',
        public_key: <PUBLIC-KEY>,
        private_key: <PRIVATE-KEY>
    }
)
```

You can simply save this as `notifications.rb` and run it with `ruby notifications.rb` to make a test.

This means that when you subscribe on the frontend, you need to save the endpoint and all other information in the backend, and associate them (maybe) with your users.

# Offline mode

When internet is not available we want to still display something to the user. Let's see how to do that. I will cover a simple offline page with an image, after that is up to you. [This is the article](https://googlechrome.github.io/samples/service-worker/custom-offline-page/) where I took inspiration from.

Start by creating an offline page:

```ruby
get 'offline', to: 'home#offline', as: :offline
```

```ruby
class HomeController < ApplicationController
  def offline
    render 'offline', layout: false
  end
end
```

we render a very simple view, without using the layout used for the rest of the application.

```
html
  head    
    css:
      body {
        background-color: #00a4cd;
        color: #ffffff;
        padding: 4rem 2rem;
      }

      .text-center {
        text-align: center;
      }
  body
    .text-center
      = image_pack_tag 'logo_white.svg'
    h1.text-center
      ' You need a working internet connection to use Agreeder
    p.text-center
      ' Offline mode is not supported yet
```

and edit your service worker as follows:

```js
const OFFLINE_VERSION = 1;
const CACHE_NAME = 'offline';
const OFFLINE_URL = 'offline';

self.addEventListener('install', function (event) {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    // Setting {cache: 'reload'} in the new request will ensure that the response
    // isn't fulfilled from the HTTP cache; i.e., it will be from the network.
    await cache.add(new Request(OFFLINE_URL, {cache: 'reload'}));
  })());
});

self.addEventListener('activate', async function (event) {
  event.waitUntil((async () => {
  // Enable navigation preload if it's supported.
  // See https://developers.google.com/web/updates/2017/02/navigation-preload
    if ('navigationPreload' in self.registration) {
      await self.registration.navigationPreload.enable();
    }
  })());

  // Tell the active service worker to take control of the page immediately.
  self.clients.claim();
});

self.addEventListener('fetch', function (event) {
  // We only want to call event.respondWith() if this is a navigation request
  // for an HTML page.
    event.respondWith((async () => {
      try {
        // First, try to use the navigation preload response if it's supported.
        const preloadResponse = await event.preloadResponse;
        if (preloadResponse) {
          return preloadResponse;
        }

        return await caches.match(event.request) || await fetch(event.request);
      } catch (error) {
        // catch is only triggered if an exception is thrown, which is likely
        // due to a network error.
        // If fetch() returns a valid HTTP response with a response code in
        // the 4xx or 5xx range, the catch() will NOT be called.
        console.log('Fetch failed; returning offline page instead.', error);

        const cache = await caches.open(CACHE_NAME);
        const cachedResponse = await cache.match(OFFLINE_URL);
        return cachedResponse;
      }
    })());
});
```

Reload your Service Worker and refresh the page. Now, you can enable Offline mode in Chrome DevTools and you should have an Offline Page!

![Offline page without image](https://dev-to-uploads.s3.amazonaws.com/i/aqoxa6mu1twcavqqu7qc.png)
<figcaption>The image is not cached and therefore not available yet in offline mode</figcaption>

To show the image we need, of course, to cache it as well. Adding it to the cache [is easy](https://developers.google.com/web/ilt/pwa/lab-caching-files-with-service-worker), simply add it where you also add the offline page:

```js
await cache.add(new Request('/packs/media/images/logo_white-a925d045a774f93a59598e709010d411.svg', {cache: 'reload'}));
```

Reload the service worker, refresh the page in "Online mode" and check if the asset is cached correctly on Chrome DevTools:

![Offline page with image](https://dev-to-uploads.s3.amazonaws.com/i/un5yedk37g6wdc9dxyva.png)

This technique works but is not the best out there, since you need to specify the exact name of the asset to cache and, if the asset changes or the offline page changes, you need to remember to also update the Service Worker. I will explain in a different article how to tackle that, but if you are in a hurry and want to find out before, you can look into [Google Workbox](https://developers.google.com/web/tools/workbox)



# Hot Module Reload

`webpack-dev-server` and hot module reloading will still work, but unfortunately not for our service workers. Webpacker middleware, by default, redirects only requests to `/packs` to webpack-dev-server, and since our service workers live in the public folder directory, they cannot be served.

I developed a small gem that adds a middleware and allows you to serve also service workers. It's called `webpacker-pwa`. Add it to your Gemfile, or copy-paste the middleware in your project from the Github project.

This Rack middleware will intercept requests for Service Workers and serve them through webpack-dev-server.

Note that the "refreshed" service worker will be loaded but not activated. This is correct! You can automatically refresh it by adding the following:

```js
self.addEventListener('install', function(event) {
  self.skipWaiting();
});
```

You can now start coding your service worker and take full advantage of Hot Module Reloading!

![Hot module reloading for Service Workers](https://dev-to-uploads.s3.amazonaws.com/i/vyosx0uosm7vxjgstapo.gif)
<figcaption>We change the title of our notifications on the fly<figcaption>

# The Progressive Rails App

You are ready to start coding your Progressive Rails App.
I wanted to show you how easy is to start with Service Workers on Rails, and I hope that Webpacker will soon allow that out-of-the-box, maybe taking inspiration from `webpacker-pwa`.
Now that you know how to write a service worker, send push notification, and implement an offline page, you can start reading specific guides to implement what you need. I hope this Guide could help you start making your Rails app a Progressive Rails App, and you will be more confident from now on, that this is a very easy task.

For other tutorials regarding Webpacker, check my previous blog posts on dev.to and medium.com.

Thanks [Renuo AG](https://renuo.ch), as always, for supporting me in writing this article and for all the improvements in the Rails ecosystem.

Take a look into [Agreeder](https://agreeder.com), is a very cool app to take decisions by sorting your preferences.

Please also check [Gifcoins](https://gifcoins.io), out internal reward system at Renuo. It's a free and easy tool to compliment each other at your company, and a different way to say "Thank you!"
