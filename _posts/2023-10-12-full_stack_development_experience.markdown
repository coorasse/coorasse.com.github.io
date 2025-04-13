---
layout: post
title: "The Full-Stack development experience"
date: 2023-10-12 14:48:00 +0100
categories: rails
excerpt: "Rails World 2023 closes many doors that have been opened recently and marks a turning point for Ruby On Rails. That is why this year's motto can be summarized as \"The One Person Framework\"."
---

[Rails World 2023](https://rubyonrails.org/world) closes many doors that have been opened recently and marks a turning point for Ruby On Rails. That is why this year's motto can be summarized as "[The One Person Framework](https://world.hey.com/dhh/the-one-person-framework-711e6318)".

The Web has certainly been a complex environment in recent years. This complexity was necessary to push browsers to the limit and use the most advanced features.

**But in 2023, this is no longer necessary!**

## Assets distribution


Let's think about CSS. For years, we used SASS to take advantage of variables and nested rules. Well, that is no longer necessary. These are both features made available directly by CSS now.


![CSS variables availability on browsers](/assets/full_stack_development_experience/css_variables.png)

![CSS nesting availability on browser](/assets/full_stack_development_experience/css_nesting.png)

So we can say goodbye to compiling SASS into CSS and enjoy the pleasure of writing directly in CSS. This makes us much faster in development and requires one less knowledge (SASS) for each Full-stack developer.

A full-Stack developer is precisely what our profession provided for before the advent of powerful javascript frameworks for creating truly fluid web interfaces! However, **it is time to simplify**! It is time to stop being Partial-stack developers and focus on productivity again.


**Let's talk about JavaScript**. The language has matured so much in the last few years, and it is (almost) a joy to write in JavaScript. The consolidation of import maps for the distribution of JavaScript and CSS assets finally allows us to remove another element from our stack: bundling.

![Import maps availability on browsers](/assets/full_stack_development_experience/import_maps.png)

In 2023, thanks to importmaps, providing the browser with dozens of separate JavaScript files instead of a single file makes no difference! No more bundling! It is not only unnecessary but even **harmful**! If we modify just one of our files, we can serve the browser a new version of that one file instead of the entire bundle. **Long live simplicity!**


An additional element that we can finally remove from our stack is the minification of JavaScript and CSS files. Thanks to algorithms like [brotli](https://github.com/google/brotli) (with a very Swiss flavour) we no longer need to minify and compress our files before distributing them. Cloudflare, Nginx, or Apache will take care of everything for us.

And there goes our stack thinning, and with that, our Full-stack developers can focus again on productivity instead of technicalities about how to distribute their work to Browsers.

Ruby On Rails, thanks to [propshaft](https://github.com/rails/propshaft), closes a chapter. Welcome to 2023, where deploying JavaScript and CSS is a breeze. Welcome to the [no-build](https://world.hey.com/dhh/you-can-t-get-faster-than-no-build-7a44131c) era.

![DHH showing no-build speed comparison graph](/assets/full_stack_development_experience/no_build.png)

## Hard drives are cool


Another element that has radically changed in recent years is the speed of drives. With the advent of NVMe disks, the speed is ten times what we had ten years ago. That is why our stack can be further streamlined. To start with a new web application, we can use the disk for databases (SQLite), caches, WebSockets, and background jobs.



![Speed of Hard Drives over the years from chatGPT so it must be true](/assets/full_stack_development_experience/hard_disks.png)

Great! It means you can have a web app with all the latest and most complex features...**and zero dependencies**.

When your application is used by millions of users worldwide, you can think about further optimizations, a better-performing database, or gain performance with more efficient caching systems. Until then, productivity is the key word. No frills and no dependencies. You can eliminate SQL and NoSQL databases from your stack and focus on development.

## HTML-First architecture

Let's get to the last chapter. The most controversial one, the one most discussed. The [Hotwire](https://hotwired.dev/) architecture: HTML Over The Wire. Ruby On Rails started down this path in 2015 with Turbolinks, but it was not until 2021, with the arrival of Turbo, that years of work was consolidated.

Today, we can confidently say that HTML Over The Wire is the right technology for maximizing productivity. When we maximize productivity, this is always at the expense of performance. With this technology, we will never have the performance of a JavaScript-First architecture. But what is it all about?

When discussing **JavaScript-First Architecture**, I have in mind applications where the backend and frontend, properly separated, communicate via JSON. The frontend uses JavaScript, and the backend also, possibly. The server and client communicate via JSON. The server is "dumb", it provides data to the client, which, thanks to the Frontend Framework from screaming, "builds" the entire web interface.

The client then has the entire responsibility of building web pages.

A truly efficient architecture that takes full advantage of all the capacity of modern devices, which have no difficulty in taking on the "onerous task." An architecture that maximizes performance...at the expense of productivity, of course. Not coincidentally, the first frameworks in this universe, Angular and React, were deployed by Google and Facebook, which have their main focus on performance. And we could do with more!


GitHub itself, which is based on Ruby On Rails, now adopts React [in many parts of their frontend](https://news.ycombinator.com/item?id=33576722) to be able to offer the best experience to its customers.


When I discuss **HTML-First Architecture**, however, I have in mind the Web of twenty years ago. The server, "intelligent", no longer solely transmits data to clients but directly HTML pages.


The client/server communication protocol is based on HTML, and the client goes back to being "stupid."


What changes today is that the client and server can communicate via HTML but update individual page elements instead of simply navigating to the next one.


This concept of partial updates allows us to rethink very complex pages into smaller elements (just as React taught us!) and update only the parts we care about.


The implementation offered by Ruby On Rails is called Turbo, and it allows for SPA-like user interfaces and experiences without having to learn a new framework.

<video poster="https://dev.37signals.com/assets/images/page-refreshes-with-morphing-demo/page-refreshes-with-morphing.webp" src="https://d2biiyjlsh52uh.cloudfront.net/dev/assets/videos/page-refreshes-with-morphing-demo/page-refreshes-with-morphing.mp4" controls=""></video>

This element allows a Full-Stack developer to build applications with a modern flavour within a [majestic monolith](https://m.signalvnoise.com/the-majestic-monolith/), while continuing to work only with HTML at all times. No more client/server separation and complex synchronization to achieve modern, fluid interfaces. Just one application, the stack of which can fit entirely in one person's head.


When they tell you about Multiple Page Apps vs. Single Page Apps, you will know **this comparison no longer makes sense**. There are JavaScript-First Frameworks that can safely create MPA's via Server-side rendering, and there are HTML-First Frameworks which can provide the same experience as an SPA.


HTML-First vs Javacript-First architecture is the distinction that needs to be made today.

## App Store, Android Store


Having come to this point, to think that one person can manage the entire stack for Web application development **is not only likely, it is reality!** One person can develop a feature from start to finish: from database design, background processes, business logic, to frontend design. The Web stack was complex, but we finally simplified it!

Yes, a Full-Stack developer in 2023 has the tools to build a feature from start to finish, without waiting for his colleague to "expose" the API.

But there is a world that has always been quite obscure to us web developers: native iOS and Android app development. Native apps do not allow us all the simplifications we discussed above. Native app development follows other rules, and here I throw up my hands and give up.

But Ruby On Rails, since a couple of weeks ago, has released the missing piece of the stack for creating hybrid applications: [Strada](https://strada.hotwired.dev/).

Thanks to Turbo and Strada, even our Full-Stack developer can make something that will be approved within the App Store. A hybrid app allows you to start from your existing Web application and release it as a native App once it is properly "wrapped" in a WebView. Turbo-ios and turbo-android, together with Strada, make it very easy to add all the native elements needed to optimize the user experience.

To date, dozens of apps are already made with this technology in the App Store, and I challenge anyone to distinguish them from a native app. Web View indeed means Browser, and Browsers are really powerful today! With good design and good animations, they are indistinguishable from fully native apps. And the beauty is that it is still your Web app. You don't need to expose APIs, and rebuild your iOS and Android interfaces. Just reuse your existing ones! **This is an incredible boost to productivity!**

## What's next?

At the beginning of the article, I wrote that this is a turning point, but what's next? The next few years will be focused on this simplification of the stack and on improving these new tools at our disposal. Improving productivity is also done through developer tools. We need time to improve the whole ecosystem around these technologies. There are many new things, and it takes time to absorb and digest them.

Ruby On Rails continues to point the way, often independently and controversially, and we, after our recent membership in the Rails Foundation, are intent on following it.

Check the [Keynote of Rails World 2023](https://www.youtube.com/watch?v=iqXjGiQ_D-A), to hear from the creator of Ruby On Rails, the concepts I took inspiration from, to write this blog post.

<iframe width="100%" height="400" src="https://www.youtube.com/embed/iqXjGiQ_D-A?si=8GWjwG5JjmkN-2xG" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
